#!/usr/bin/env python3
"""Generate independent external list READ/BACKSPACE fixtures from pinned source bytes."""
from pathlib import Path
import argparse,hashlib,json
ROOT=Path(__file__).resolve().parent
SOURCE_SHA='c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883'
BODIES=[('read_alloc_char',790,813),('present_and_true',1400,1408),('default_logical',3687,3697),('default_character',3723,3733)]

def generate(original,root=ROOT):
 data=Path(original).read_bytes()
 if hashlib.sha256(data).hexdigest()!=SOURCE_SHA: raise ValueError('Original source digest mismatch')
 lines=data.splitlines(keepends=True); blocks=[]; provenance=[]
 for name,start,end in BODIES:
  block=b''.join(lines[start-1:end]);blocks.append(block)
  provenance.append(dict(procedure=name,start_line=start,end_line=end,sha256=hashlib.sha256(block).hexdigest()))
 root.mkdir(exist_ok=True);(root/'cases').mkdir(exist_ok=True)
 cases=[];diagnostics={}
 def add(name,decl,body,inputs='1\n',expected='1\n',mode='tokens',category='success',baseline='run',pin=None,full=None,original_body=False):
  source=(full if full is not None else ('program p\nimplicit none\ninteger::u\n'+decl+'\nu=27\n'+body+'\nend program\n').encode())
  case=dict(name=name,source='cases/'+name+'.f90',category=category,baseline=baseline,expected_stdout=expected,compare_mode=mode)
  if inputs is not None:case['inputs']=inputs if isinstance(inputs,dict) else {'27':inputs}
  if original_body:case['original_body']=True
  (root/case['source']).write_bytes(source)
  if category!='success':
   if pin:
    marker,column,message=pin
    match=[i+1 for i,line in enumerate(source.decode().splitlines()) if marker==line]
    if len(match)!=1: raise ValueError((name,marker,match))
    diagnostics[name]=dict(source=case['source'],source_sha256=hashlib.sha256(source).hexdigest(),line=match[0],column=column,message=message)
   else:
    diagnostics[name]=dict(source=case['source'],source_sha256=hashlib.sha256(source).hexdigest(),pending_contract=True)
  cases.append(case)
 def ok(name,decl,body,inputs,expected='1\n',mode='tokens',**kw):add(name,decl,body,inputs,expected,mode,**kw)
 # Numeric outputs are compared as exact finite Decimals, never binary float tolerances.
 ok('integer_kinds','integer(4)::a(3)\ninteger(8)::b(3)\ninteger::s',
    'read(u,*,iostat=s)a,b\nif(s/=0)stop 1\nprint *,a,b',
    '-2147483648,0,2147483647, -9223372036854775808,9007199254740993,9223372036854775807\n',
    '-2147483648 0 2147483647 -9223372036854775808 9007199254740993 9223372036854775807\n')
 ok('real_kinds','real(4)::a(3)\nreal(8)::b(3)\ninteger::s',
    'read(u,*,iostat=s)a,b\nif(s/=0)stop 1\nprint *,a,b','1.25,-2.5E+1,3D0, .125d+1,-.5,6.25\n','1.25 -25 3 1.25 -.5 6.25\n')
 ok('real_signed_zero','real(4)::a\nreal(8)::b\ninteger::s','read(u,*,iostat=s)a,b\nif(s/=0)stop 1\nprint *,a,b','-0.0,-0d0\n','-0 -0\n')
 ok('real_tiny_nonzero','real(8)::a\ninteger::s','read(u,*,iostat=s)a\nif(s/=0.or.a<=0d0.or.a>=1d-299)stop 1\nprint *,1','1d-300\n')
 ok('numeric_rank_three','integer::a(2,1,2),s\nreal(8)::b(1,2,2)',
    'read(u,*,iostat=s)a,b\nif(s/=0)stop 1\nprint *,a,b','1 2\n3 4 1.5\n2.5 3.5 4.5\n','1 2 3 4 1.5 2.5 3.5 4.5\n')
 ok('allocated_rank_two','integer,allocatable::a(:,:)\nreal(8),allocatable::b(:,:)\ninteger::s',
    'allocate(a(2,2),b(2,2))\nread(u,*,iostat=s)a,b\nif(s/=0)stop 1\nprint *,a,b','1 2 3 4\n4*1.5\n','1 2 3 4 1.5 1.5 1.5 1.5\n')
 ok('character_padding_truncation','character(4)::a,b,c\ninteger::s','read(u,*,iostat=s)a,b,c\nif(s/=0)stop 1\nprint "(a)","["//a//"]","["//b//"]","["//c//"]"',"a abcdef ''\n",'[a   ]\n[abcd]\n[    ]\n','bytes')
 ok('character_delimiters_doubling','character(8)::a(4)\ninteger::s',
    'read(u,*,iostat=s)a\nif(s/=0)stop 1\nprint "(a)",a',"'a,b / *' \"say \"\"x\"\"\" 'it''s' plain\n",'a,b / * \nsay "x" \nit\'s    \nplain   \n','bytes')
 ok('character_rank_three','character(2)::a(2,1,2)\ninteger::s','read(u,*,iostat=s)a\nif(s/=0)stop 1\nprint "(a)",a','a bb ccc dd\n','a \nbb\ncc\ndd\n','bytes')
 ok('allocated_character_lengths','character(:),allocatable::a(:,:),b\ninteger::s',
    'allocate(character(3)::a(2,2))\nallocate(character(2)::b)\nread(u,*,iostat=s)a,b\nif(s/=0.or.len(a)/=3.or.len(b)/=2)stop 1\nprint "(a)",a,b',"x 'y z' abcdef '' long\n",'x  \ny z\nabc\n   \nlo\n','bytes')
 ok('mixed_targets','integer::a,s\nreal(8)::b\ncharacter(4)::c(2)',
    'read(u,*,iostat=s)a,b,c\nif(s/=0.or.a/=42.or.b/=1.5d0)stop 1\nprint "(a)",c',"42\n1.5 'a b',xyz\n",'a b \nxyz \n','bytes')
 ok('multirecord_discard_tail','integer::a(3),b,s',
    'read(u,*,iostat=s)a\nif(s/=0)stop 1\nread(u,*,iostat=s)b\nif(s/=0)stop 2\nprint *,a,b','1\n\n2\n3 99 98\n4\n','1 2 3 4\n')
 ok('record_end_leading_comma','integer::a(3),b,s',
    'read(u,*,iostat=s)a\nif(s/=0)stop 1\nread(u,*,iostat=s)b\nif(s/=0)stop 2\nprint *,a,b','1\n,2,3\n4\n','1 2 3 4\n')
 ok('record_end_double_comma_null','integer::a(4),b,s',
    'a=9\nread(u,*,iostat=s)a\nif(s/=0)stop 1\nread(u,*,iostat=s)b\nif(s/=0)stop 2\nprint *,a,b','1,\n,2,3\n4\n','1 9 2 3 4\n')
 ok('quoted_continuation','character(8)::a,b\ninteger::s',
    'read(u,*,iostat=s)a,b\nif(s/=0)stop 1\nprint "(a)",a,b',"'ab\ncd', 'e\nf'\n",'abcd    \nef      \n','bytes')
 ok('quoted_continuation_spaces','character(10)::a\ninteger::s',
    'read(u,*,iostat=s)a\nif(s/=0)stop 1\nprint "(a)",a',"'ab  \n  cd'\n",'ab    cd  \n','bytes')
 ok('quoted_continuation_empty_crlf','character(8)::a\ninteger::s',
    'read(u,*,iostat=s)a\nif(s/=0)stop 1\nprint "(a)",a',"'ab\r\n\r\ncd'\r\n",'abcd    \n','bytes')
 ok('nulls_slash_preserve','integer::a(5),s',
    'a=[1,2,3,4,5]\nread(u,*,iostat=s)a\nif(s/=0)stop 1\nprint *,a',',9,2*,/ ignored\n','1 9 3 4 5\n')
 ok('character_nulls_slash','character(3)::a(4)\ninteger::s',
    "a=['one','two','tri','for']\nread(u,*,iostat=s)a\nif(s/=0)stop 1\nprint '(a)',a",",'x',/ tail\n",'one\nx  \ntri\nfor\n','bytes')
 ok('repeat_cross_items','integer::a(2),b(2),s',
    'read(u,*,iostat=s)a,b\nif(s/=0)stop 1\nprint *,a,b','4*7\n','7 7 7 7\n')
 ok('repeat_character_lengths','character(2)::a\ncharacter(5)::b\ninteger::s',
    'read(u,*,iostat=s)a,b\nif(s/=0)stop 1\nprint "(a)",a,b',"2*'abc'\n",'ab\nabc  \n','bytes')
 ok('repeat_null_cross_types','integer::a,s\nreal(8)::b\ncharacter(3)::c',
    'a=7\nb=1.5d0\nc="old"\nread(u,*,iostat=s)a,b,c\nif(s/=0.or.a/=7.or.b/=1.5d0)stop 1\nprint "(a)",c','3*\n','old\n','bytes')
 ok('repeat_reset','integer::a,b,s',
    'read(u,*,iostat=s)a\nif(s/=0)stop 1\nread(u,*,iostat=s)b\nif(s/=0)stop 2\nprint *,a,b','5*7\n8\n','7 8\n')
 ok('zero_sized_advance','integer::a(0),b,s',
    'read(u,*,iostat=s)a\nif(s/=0)stop 1\nread(u,*,iostat=s)b\nif(s/=0)stop 2\nprint *,b','11\n22\n','22\n')
 ok('empty_list_advance','integer::b,s',
    'read(u,*,iostat=s)\nif(s/=0)stop 1\nread(u,*,iostat=s)b\nif(s/=0)stop 2\nprint *,b','11\n22\n','22\n')
 ok('zero_length_character','character(0)::a(2)\ninteger::b,s',
    'read(u,*,iostat=s)a,b\nif(s/=0)stop 1\nprint *,b',"'long' xyz 7\n",'7\n')
 ok('eof_and_past_endfile','integer::a,s',
    'read(u,*,iostat=s)a\nif(s>=0)stop 1\nread(u,*,iostat=s)a\nif(s<=0)stop 2\nprint *,1','')
 ok('empty_target_eof','integer::a(0),s',
    'read(u,*,iostat=s)a\nif(s>=0)stop 1\nread(u,*,iostat=s)a\nif(s<=0)stop 2\nprint *,1','')
 ok('short_multirecord_eof','integer::a(3),s','read(u,*,iostat=s)a\nif(s>=0)stop 1\nprint *,1','1\n2\n')
 for name,decl,value in [('bad_integer','integer::a','nope'),('integer_overflow','integer::a','2147483648'),('bad_real','real(8)::a','1.2xyz'),('real_overflow','real(8)::a','1e9999')]:
  ok(name,decl+'\ninteger::s','read(u,*,iostat=s)a\nif(s<=0)stop 1\nprint *,1',value+'\n',baseline='compile' if name=='real_overflow' else 'run')
  if name=='real_overflow':cases[-1]['reason']='GNU accepts Infinity; FortFront deliberately applies its existing finite-value input policy.'
 ok('keyword_iostat_kind8','integer(8)::v,s\ninteger::a',
    'v=27\nread(unit=v,fmt=*,iostat=s)a\nif(s/=0)stop 1\nprint *,a','4\n','4\n')
 for name,syntax in [('backspace_parens','backspace(u)'),('backspace_bare','backspace u'),('backspace_keywords','backspace(unit=u,iostat=s)')]:
  ok(name,'integer::a,b,s','read(u,*)a\n'+syntax+'\nread(u,*,iostat=s)b\nif(s/=0)stop 1\nprint *,a,b','11 99\n22\n','11 11\n')
 ok('backspace_at_start_connected','integer::a,s',
    'read(u,*)a\nbackspace(u)\nbackspace(u,iostat=s)\nif(s/=0)stop 1\nread(u,*)a\nprint *,a','11\n','11\n')
 ok('backspace_after_eof','integer::a,s',
    'read(u,*)a\nread(u,*,iostat=s)a\nif(s>=0)stop 1\nbackspace(u,iostat=s)\nif(s/=0)stop 2\nread(u,*,iostat=s)a\nif(s>=0)stop 3\nbackspace(u)\nbackspace(u)\nread(u,*,iostat=s)a\nif(s/=0)stop 4\nprint *,a','11\n','11\n')
 ok('backspace_after_spanning','integer::a(2),b,s',
    'read(u,*)a\nbackspace(u)\nread(u,*,iostat=s)b\nif(s/=0)stop 1\nprint *,a,b','11\n22\n33\n','11 22 22\n')
 ok('backspace_unterminated_final','integer::a,b,s',
    'read(u,*)a\nbackspace(u)\nread(u,*,iostat=s)b\nif(s/=0)stop 1\nprint *,a,b','11','11 11\n')
 ok('backspace_crlf_empty_record','integer::a,s\ncharacter(4)::line',
    'read(u,*)a\nread(u,"(a)")line\nif(line/=" ")stop 1\nbackspace(u)\nread(u,"(a)")line\nif(line/=" ")stop 2\nread(u,*)a\nprint *,a','11\r\n\r\n22\r\n','22\n')
 ok('backspace_read_mode_mixed','integer::a,s\ncharacter(6)::line',
    'read(u,*)a\nbackspace(u)\nread(u,"(a)",iostat=s)line\nif(s/=0)stop 1\nprint "(a)",line','12 34\n','12 34 \n','bytes')
 ok('independent_units','integer::v,a,b,c,s',
    'v=28\nread(u,*)a\nread(v,*)b\nbackspace(u)\nread(u,*)c\nprint *,a,b,c',{'27':'11\n22\n','28':'44\n55\n'},'11 44 11\n')
 # Additional lexer, cursor and procedure-call edge cases.
 ok('quoted_separate_records','character(3)::a,b\ninteger::s',
    'read(u,*,iostat=s)a,b\nif(s/=0)stop 1\nprint "(a)",a,b',"'a'\n'b'\n",'a  \nb  \n','bytes')
 ok('error_then_backspace','integer::a,s\ncharacter(8)::line',
    'read(u,*,iostat=s)a\nif(s<=0)stop 1\nbackspace(u)\nread(u,"(a)",iostat=s)line\nif(s/=0)stop 2\nprint "(a)",line','bad data\n','bad data\n','bytes')
 ok('repeat_cross_type_error','integer::a,s\ncharacter(3)::b',
    'read(u,*,iostat=s)a,b\nif(s<=0)stop 1\nprint *,1','2*12\n')
 ok('repeat_cross_kind_error','integer(4)::a\ninteger(8)::b\ninteger::s',
    'read(u,*,iostat=s)a,b\nif(s<=0)stop 1\nprint *,1','2*12\n')
 ok('repeat_overflow','integer::a,s','read(u,*,iostat=s)a\nif(s<=0)stop 1\nprint *,1','9223372036854775808*1\n')
 ok('trailing_quote_junk','character(3)::a\ninteger::s','read(u,*,iostat=s)a\nif(s<=0)stop 1\nprint *,1',"'a'x\n")
 ok('blank_only_records','integer::a(2),s','read(u,*,iostat=s)a\nif(s/=0)stop 1\nprint *,a',' \n\t\n11\n22\n','11 22\n')
 ok('nondelimited_character_end_record','character(3)::a(2)\ninteger::s','read(u,*,iostat=s)a\nif(s/=0)stop 1\nprint "(a)",a','ab\ncd\n','ab \ncd \n','bytes')
 ok('slash_does_not_consume_next_record','integer::a,b,s','a=9\nread(u,*,iostat=s)a\nif(s/=0)stop 1\nread(u,*,iostat=s)b\nif(s/=0)stop 2\nprint *,a,b','/ ignored\n11\n','9 11\n')
 ok('backspace_empty_file','integer::a,s','read(u,*,iostat=s)a\nif(s>=0)stop 1\nbackspace(u)\nbackspace(u,iostat=s)\nif(s/=0)stop 2\nread(u,*,iostat=s)a\nif(s>=0)stop 3\nprint *,1','')
 ok('backspace_kind8_unit','integer(8)::v,s\ninteger::a','v=27\nread(v,*)a\nbackspace(unit=v,iostat=s)\nif(s/=0)stop 1\nread(v,*)a\nprint *,a','11\n','11\n')
 full=b'module m\nimplicit none\ncontains\nsubroutine read_one(u,a)\ninteger,intent(in)::u\ninteger,intent(out)::a\nread(u,*)a\nend subroutine\nsubroutine replay_one(u,a)\ninteger,intent(in)::u\ninteger,intent(out)::a\nbackspace(u)\ncall read_one(u,a)\nend subroutine\nend module\nprogram p\nuse m\nimplicit none\ninteger::u,a,b,c\nu=27\ncall read_one(u,a)\ncall read_one(u,b)\ncall replay_one(u,c)\nprint *,a,b,c\nend program\n'
 add('nested_call_cursor','','','11\n22\n33\n','11 22 22\n',full=full)
 ok('backspace_scalar_identifier','integer::backspace,a',
    'backspace=27\nread(backspace,*)a\nbackspace(backspace)\nread(backspace,*)a\nprint *,a','11\n','11\n')
 ok('backspace_array_identifier','integer::backspace(2),a',
    'backspace(1)=27\nbackspace(2)=28\nu=backspace(1)\nread(u,*)a\nbackspace u\nread(u,*)a\nprint *,a,backspace',{'27':'11\n'},'11 27 28\n')
 ok('quoted_repeat_multirecord','character(4)::a(2)\ninteger::b,s',
    'read(u,*,iostat=s)a,b\nif(s/=0.or.b/=3)stop 1\nprint "(a)",a',"2*'a\nb',3\n",'ab  \nab  \n','bytes')
 ok('null_repeat_record_comma','integer::a(5),s',
    'a=9\nread(u,*,iostat=s)a\nif(s/=0)stop 1\nprint *,a','1 2*\n,3,4\n','1 9 9 3 4\n')
 add('character_error_invalidates_prefix','character(4)::word\ninteger::a,s',
     'word="old"\nread(u,*,iostat=s)word,a\nprint *,word',"'new' bad\n",'',category='runtime',baseline='compile',
     pin=('print *,word',9,'read of uninitialized variable word'))
 # Actual upstream procedure body plus actual required procedure bodies, preserving CRLF.
 module=b'module utility_slice\nimplicit none\ninterface default\nmodule procedure default_logical,default_character\nend interface\ncontains\n'+b''.join(blocks)+b'end module\n'
 originals=[
 ('original_next_record',"call read_alloc_char(u,xx,n)",'3\na bb ccc\n','a   \nbb  \nccc \n',3),
 ('original_same_record',"call read_alloc_char(u,xx,n,same_line=.true.)",'3 a bb ccc\n','a   \nbb  \nccc \n',3),
 ('original_same_record_quoted',"call read_alloc_char(u,xx,n,same_line=.true.)","3 'a b' 'c,d' 'e/f'\n",'a b \nc,d \ne/f \n',3),
 ('original_multirecord',"call read_alloc_char(u,xx,n)",'3\na\nbb\nccc\n','a   \nbb  \nccc \n',3),
 ('original_zero_next',"call read_alloc_char(u,xx,n)",'0\nskipped\n','',0),
 ('original_negative_next',"call read_alloc_char(u,xx,n)",'-2\nskipped\n','',0),
 ('original_zero_same',"call read_alloc_char(u,xx,n,same_line=.true.)",'0 ignored\n','',0),
 ('original_print_no_label',"call read_alloc_char(u,xx,n,print_vec=.true.)",'2\na bb\n','                               : a bb\na   \nbb  \n',2),
 ('original_explicit_false',"call read_alloc_char(u,xx,n,same_line=.false.)",'2\na bb\n','a   \nbb  \n',2),
 ('original_print_label',"call read_alloc_char(u,xx,n,print_vec=.true.,label='items')",'2\na bb\n','                          items: a bb\na   \nbb  \n',2),
 ]
 for name,call,inp,out,n in originals:
  driver=('program p\nuse utility_slice\nimplicit none\ninteger::u,n\ncharacter(4),allocatable::xx(:)\nu=27\n'+call+'\nif(n/='+str(n)+'.or.size(xx)/='+str(n)+')stop 1\nprint "(a)",xx\nend program\n').encode()
  # Empty arrays produce a blank record for formatted output; skip printing them instead.
  if n==0:driver=driver.replace(b'print "(a)",xx\n',b'')
  add(name,'','',inp,out,'bytes',full=module+driver,original_body=True)
 # Pins here are contracts shared with existing diagnostics, not captured candidate output.
 for name,body,inputs,message,marker,column in [
  ('eof_invalidates_prefix','a=7\nb=8\nread(u,*,iostat=s)a,b\nprint *,a','1\n','read of uninitialized variable a','print *,a',9),
  ('error_invalidates_prefix','a=7\nb=8\nread(u,*,iostat=s)a,b\nprint *,a','1 bad\n','read of uninitialized variable a','print *,a',9),
  ('null_preserves_undefined','read(u,*,iostat=s)a\nprint *,a',',\n','read of uninitialized variable a','print *,a',9),
  ('slash_preserves_undefined','read(u,*,iostat=s)a\nprint *,a','/\n','read of uninitialized variable a','print *,a',9),
  ('unbound_read','read(u,*,iostat=s)a',None,'external input unit is not explicitly bound','read(u,*,iostat=s)a',1),
 ]:
  add(name,'integer::a,b,s',body,inputs,'',category='runtime',baseline='compile',pin=(marker,column,message))
 for name,decl,body,inputs in [
  ('unbound_backspace','integer::s','backspace(u,iostat=s)',None),
  ('backspace_negative_unit','integer::s','u=-1\nbackspace(u,iostat=s)',None),
  ('backspace_undefined_unit','integer::v,s','backspace(v,iostat=s)',None),
  ('read_logical_unsupported','logical::a','read(u,*)a','T\n'),
  ('read_complex_unsupported','complex::a','read(u,*)a','(1,2)\n'),
  ('read_element_unsupported','integer::a(2)','read(u,*)a(1)','1\n'),
  ('read_implied_do_unsupported','integer::a(2),i','read(u,*)(a(i),i=1,2)','1 2\n'),
  ('read_alias_targets','integer::a','read(u,*)a,a','1 2\n'),
  ('backspace_literal_unit','','backspace(27)',None),
  ('backspace_extra_control','integer::s','backspace(u,iostat=s,err=10)\n10 continue',None),
 ]:
  cat='runtime' if name.startswith('unbound') or name in ('backspace_negative_unit','backspace_undefined_unit') else 'invalid'
  external_message='External READ requires an INTEGER unit variable, list-directed whole local numeric or CHARACTER targets or literal (A) scalar CHARACTER or local CHARACTER element without user-call or IOSTAT-dependent indices, and optional INTEGER IOSTAT outside PURE/SIMPLE procedures'
  backspace_message='BACKSPACE requires an INTEGER unit variable and optional distinct local INTEGER IOSTAT outside PURE/SIMPLE procedures'
  statement=body.splitlines()[0]
  if name=='unbound_backspace':pin=(statement,1,'external input unit is not explicitly bound')
  elif name=='backspace_negative_unit':pin=('backspace(u,iostat=s)',1,'external input requires a positive bound unit number')
  elif name=='backspace_undefined_unit':pin=(statement,11,'read of uninitialized variable v')
  elif name=='backspace_literal_unit':pin=(statement,len(statement)+1,backspace_message)
  elif name=='backspace_extra_control':pin=(statement,statement.index(',err')+1,'Expected ), found ,')
  elif name=='read_complex_unsupported':pin=('complex::a',1,'Undeclared variable or unsupported statement: complex')
  elif name=='read_implied_do_unsupported':pin=(statement,statement.index(',i=')+1,'Expected ), found ,')
  else:pin=(statement,len(statement)+1,external_message)
  add(name,decl,body,inputs,'',category=cat,baseline='compile',pin=pin)
 (root/'manifest.json').write_text(json.dumps(dict(cases=cases),indent=2)+'\n')
 (root/'diagnostics.json').write_text(json.dumps(dict(schema_version=1,negative_cases=diagnostics),indent=2)+'\n')
 (root/'provenance.json').write_text(json.dumps(dict(source_sha256=SOURCE_SHA,bodies=provenance),indent=2)+'\n')
 return len(cases)
if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--original-source',type=Path,default=ROOT.parent/'utilities_slices/source/xutilities.f90');ap.add_argument('--output',type=Path,default=ROOT);a=ap.parse_args();print(generate(a.original_source,a.output))
