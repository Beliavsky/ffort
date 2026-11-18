from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parent
CASES=[]
def program(decl,body,procedures=''):
 return 'program p\nimplicit none\n'+decl+'\n'+body+'\n'+('contains\n'+procedures+'\n' if procedures else '')+'end program\n'
def add(name,src,out,inputs=None,kind='success',diagnostic=None,numeric_lines=None,flags=None,features=None):
 p=ROOT/'cases'/(name+'.f90');p.write_bytes(src.encode());c=dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),category=kind,expected_stdout=out,gnu='run' if kind=='success' else 'compile',features=features or [])
 if diagnostic:c['diagnostic']=diagnostic
 if numeric_lines:c['numeric_lines']=numeric_lines
 if flags:c['gnu_flags']=flags
 if inputs:
  c['inputs']=[]
  for unit,raw in inputs.items():
   if isinstance(raw,str):raw=raw.encode()
   p=ROOT/'inputs'/(name+'.'+str(unit)+'.txt');p.write_bytes(raw);c['inputs'].append(dict(unit=unit,file='inputs/'+p.name,sha256=hashlib.sha256(raw).hexdigest(),bytes=len(raw)))
 CASES.append(c)
add('missing_argument_cursor',program('character(4)::b\ninteger::n,s',"b='junk'\ncall get_command_argument(1,value=b,length=n,status=s)\nif(s<=0.or.n/=0.or.b/='')error stop 1\nwrite(*,'(a,t2,a)',advance='no')'ABCDE','x'\nwrite(*,'(tr1,a)')'!'"),'AxC!E\n',features=['process missing argument','nonadvancing suffix','TR'])
add('argument_allocated_name',program('character(:),allocatable::name\ninteger::n,s',"call get_command_argument(0,length=n,status=s)\nif(s/=0.or.n<=0)error stop 1\nallocate(character(len=n)::name)\ncall get_command_argument(0,value=name,status=s)\nif(s/=0.or.len_trim(name)/=n)error stop 2\nprint '(a,l1)','name=',lgt(name,'')"),'name=T\n',features=['process argument length','allocatable CHARACTER','LGT'])
add('cwd_lexical_position',program('character(1024)::cwd\ninteger::s',"call getcwd(cwd,s)\nif(s/=0.or.len_trim(cwd)==0)error stop 1\nprint '(a,t10,l1)','cwd=',lle(cwd,cwd//' ')"),'cwd=     T\n',flags=['-std=gnu'],features=['GETCWD extension','LLE blank padding','T'])
add('nested_process_pending_record',program('integer::n,s',"call get_command_argument(0,length=n,status=s)\nif(s/=0.or.n<=0)error stop 1\nwrite(*,'(a,t2,a)',advance='no')'ABCD','x'\ncall helper()\nwrite(*,'(a)')'!'",'''subroutine helper()
integer::m,st
call get_command_argument(0,length=m,status=st)
if(st/=0.or.m<=0)error stop 2
write(*,'(tl10,a)',advance='no')'Z'
end subroutine'''),'AxZ!\n',features=['nested process context','nonadvancing shared suffix','TL'])
add('external_mixed_norm_lexical',program('integer::u,s\ncharacter(80)::line\ncharacter(4)::a,b\nreal(8)::v(2)',"u=27\nread(u,'(a)',iostat=s)line\nif(s/=0)error stop 1\nread(line,*,iostat=s)v,a,b\nif(s/=0)error stop 2\nprint '(f5.1,1x,a,1x,l1)',norm2(v),a,lgt(a,b)"),'  5.0 a,b  T\n',{27:'3 4 "a,b" "Z"\n'},features=['external input','mixed internal CHARACTER READ','NORM2','LGT'])
add('external_transpose_implied_positions',program('integer::u,s,i\ncharacter(80)::line\nreal(8)::a(2,2),b(2,2)',"u=27\nread(u,'(a)')line\nread(line,*)a\nb=transpose(a)\nprint '(*(f4.0,tl1,a))',(b(i,1),'X',i=1,2)\nprint '(2f5.1)',norm2(b,dim=1)"),'  3X  4X\n  5.0 13.0\n',{27:'3 5 4 12\n'},features=['external and internal READ','TRANSPOSE','NORM2 DIM','output implied-DO','TL overwrite'])
add('allocatable_external_internal_fields',program('integer::u,s\ncharacter(:),allocatable::line,a,b\nreal(8)::v(2)',"u=27\nallocate(character(len=80)::line)\nallocate(character(len=5)::a,b)\nread(u,'(a)')line\nread(line,*,iostat=s)v,a,b\nif(s/=0.or.len(a)/=5.or.len(b)/=5)error stop 1\nprint '(a,1x,a,1x,f4.1,1x,l1)',a,b,norm2(v),llt(b,a)"),'hello a,b    5.0 T\n',{27:'3 4 "hello" "a,b"\n'},features=['allocatable CHARACTER lengths','external/mixed READ','NORM2','LLT'])
add('two_inputs_shared_procedure_cursor',program('integer::u,v\ncharacter(8)::line',"u=27\nv=28\nread(u,'(a)')line\nwrite(*,'(a)',advance='no')trim(line)\ncall next_line()\nread(v,'(a)')line\nprint '(tr1,a)',trim(line)",'''subroutine next_line()
integer::unit_number
character(8)::word
unit_number=27
read(unit_number,'(a)')word
write(*,'(tr1,a)',advance='no')trim(word)
end subroutine'''),'one two tail\n',{27:'one\ntwo\n',28:'tail\n'},features=['two explicit input units','shared nested input cursor','nonadvancing TR'])
add('crlf_and_final_record',program('integer::u,s\ncharacter(8)::a,b',"u=27\nread(u,'(a)',iostat=s)a\nif(s/=0)error stop 1\nread(u,'(a)',iostat=s)b\nif(s/=0)error stop 2\nprint '(a,1x,a,1x,l1)',trim(a),trim(b),lge(b,a)"),'alpha beta T\n',{27:b'alpha\r\nbeta'},features=['CRLF and unterminated final record','LGE'])
add('quoted_repeat_null_slash',program('integer::s\ncharacter(100)::line\ncharacter(5)::a(3)\nreal(8)::v(2)',"a='keep'\nv=0\nline='3 4 2*"+'"a,b"'+", /'\nread(line,*,iostat=s)v,a\nif(s/=0)error stop 1\nprint '(3(a,1x),f4.1)',a,norm2(v)"),'a,b   a,b   keep   5.0\n',features=['mixed repeated CHARACTER input','null/slash definedness','NORM2'])
add('character_cube_lexical_count',program('integer::s\ncharacter(80)::line\ncharacter(2)::words(2,1,2)\nlogical::mask(2,1,2)',"line='"+'"a" "b" "b " "z"'+"'\nread(line,*,iostat=s)words\nif(s/=0)error stop 1\nmask=lge(words,'b')\nprint '(i0,1x,4l1)',count(mask),mask"),'3 FTTT\n',features=['rank-three CHARACTER READ','elemental lexical comparison','COUNT'])
add('transpose_alias_norm_reduction',program('real(8),allocatable::a(:,:)\nreal(8)::v(2)',"allocate(a(2,3))\na=reshape([3d0,0d0,4d0,0d0,0d0,12d0],[2,3])\na=transpose(a)\nv=norm2(a,dim=1)\nprint '(2i2,2f6.1)',shape(a),v"),' 3 2   5.0  12.0\n',features=['allocatable array reallocation','TRANSPOSE alias','NORM2 DIM','SHAPE'])
add('signed_zero_empty_norm',program('real(8)::empty(0),z(2)',"z=-0.0d0\nprint '(3es25.17)',norm2(empty),norm2(z),-0.0d0"),'0.0 0.0 -0.0\n',numeric_lines=[0],features=['NORM2 empty positive zero','negative zero retained','exact Decimal comparator'])
add('read_numbers_transposed_norm_dim',program('integer::s\ncharacter(60)::line\nreal(8)::a(2,2),b(2,2)',"line='3 4 5 12'\nread(line,*,iostat=s)a\nif(s/=0)error stop 1\nb=transpose(a)\nprint '(2f8.2)',norm2(b,dim=2)"),'5.0 13.0\n',numeric_lines=[0],features=['internal numeric READ','TRANSPOSE','NORM2 DIM exact values'])
add('empty_lexical_does_not_read',program('character(2)::a(0)\nlogical::m(0)\nreal(8)::z(0)',"m=llt(a,'x')\nprint '(i0,1x,l1,1x,f3.1)',size(m),all(m),norm2(z)"),'0 T 0.0\n',features=['typed empty CHARACTER','lexical empty array','NORM2 empty'])
add('allocated_query_format_and_read',program('character(:),allocatable::fmt,buf\ninteger::n,s\nreal(8)::v(2)',"allocate(character(len=20)::fmt)\ncall get_command_argument(1,value=fmt,length=n,status=s)\nif(s<=0.or.n/=0.or.fmt/='')error stop 1\nfmt='(a,t8,f4.1)'\nallocate(character(len=20)::buf)\nbuf='3 4'\nread(buf,*)v\nprint fmt,'norm',norm2(v)"),'norm    5.0\n',features=['process output to allocated CHARACTER','runtime format','mixed storage','NORM2','T'])
add('external_eof_then_process',program('integer::u,s,n,ps\ncharacter(8)::line,missing',"u=27\nread(u,'(a)',iostat=s)line\nif(s/=0)error stop 1\nprint '(a)',trim(line)\nread(u,'(a)',iostat=s)line\nif(s>=0)error stop 2\ncall get_command_argument(1,value=missing,length=n,status=ps)\nprint '(l1,1x,l1)',s<0,ps>0.and.n==0.and.missing==''"),'done\nT T\n',{27:'done\n'},features=['EOF IOSTAT','process query after READ','no undefined target evaluation'])
add('external_zero_length_advances',program('integer::u,s\ncharacter(0)::empty\ncharacter(8)::line',"u=27\nread(u,'(a)',iostat=s)empty\nif(s/=0)error stop 1\nread(u,'(a)',iostat=s)line\nif(s/=0)error stop 2\nprint '(a,1x,l1)',trim(line),lle(empty,' ')"),'second T\n',{27:'discard this\nsecond\n'},features=['zero-length READ target','external cursor advance','LLE blank padding'])
add('format_read_quoted_text',program('integer::s\ncharacter(80)::line\ncharacter(24)::fmt\ncharacter(5)::label\nreal(8)::v(2)',"line='"+'\"(a,t8,f4.1)\" \"norm\" 3 4'+"'\nread(line,*,iostat=s)fmt,label,v\nif(s/=0)error stop 1\nprint fmt,trim(label),norm2(v)"),'norm    5.0\n',features=['quoted CHARACTER internal READ','runtime format','T','NORM2'])
add('partial_internal_failure_no_new_output',program('integer::s\ncharacter(80)::line\ncharacter(5)::word\nreal(8)::v(2)',"write(*,'(a,t2,a)',advance='no')'ABCD','x'\nline='"+'\"hello\" bad 4'+"'\nread(line,*,iostat=s)word,v\nif(s<=0)error stop 1\nprint '(a)',word"),'AxCD',kind='runtime',diagnostic='read of uninitialized variable word',features=['mixed READ failure invalidates prior target','pending suffix atomicity'])
add('unbound_input_after_query',program('integer::u,n,s\ncharacter(12)::line',"call get_command_argument(0,length=n,status=s)\nif(s/=0.or.n<=0)error stop 1\nprint '(a)','SAFE'\nu=27\nread(u,'(a)')line"),'SAFE\n',kind='runtime',diagnostic='external READ unit is not explicitly bound',features=['process query','explicit input authority','atomic failure'])
add('bad_dynamic_dim_after_read',program('integer::u,d\ncharacter(30)::line\nreal(8)::a(2,2)',"u=27\nread(u,'(a)')line\nread(line,*)a\nd=3\nprint '(a)','SAFE'\nprint '(2f5.1)',norm2(a,dim=d)"),'SAFE\n',{27:'3 4 5 12\n'},kind='runtime',diagnostic='NORM2 DIM is outside ARRAY rank',features=['external/internal READ','dynamic NORM2 DIM rejection','output atomicity'])
add('norm_overflow_after_pending_record',program('real(8)::v(2)',"v=huge(0d0)\nwrite(*,'(a)',advance='no')'SAFE'\nprint '(g0)',norm2(v)"),'SAFE',kind='runtime',diagnostic='NORM2 result exceeds REAL range',features=['finite NORM2 policy','pending record failure'])
add('nonascii_lexical_output_atomic',program('character(2)::a\ninteger::u',"u=27\nread(u,'(a)')a\nprint '(a)','SAFE'\nprint '(l1)',llt(a,'z')"),'SAFE\n',{27:b'a\xc8\n'},kind='runtime',diagnostic='lexical comparison supports ASCII characters (0:127)',features=['whole-string lexical repertoire check','atomic formatted output'])
add('position_cap_after_explicit_read',program('integer::u\ncharacter(8)::line',"u=27\nread(u,'(a)')line\nwrite(*,'(a)',advance='no')trim(line)\nprint '(t65536,a)','X'"),'P',{27:'P\n'},kind='runtime',diagnostic='combined output record exceeds character limit',features=['explicit READ','unchanged pending record cap','T atomicity'])
add('argument_zero_identity_from_input',program('integer::u,n,s,k\ncharacter(80)::expected\ncharacter(:),allocatable::name',"u=27\nread(u,'(a)')expected\nk=len_trim(expected)\ncall get_command_argument(0,length=n,status=s)\nif(s/=0.or.n<k)error stop 1\nallocate(character(len=n)::name)\ncall get_command_argument(0,value=name,status=s)\nif(s/=0)error stop 2\nprint '(a,l1)','argv0=',lle(name(n-k+1:n),expected).and.lge(name(n-k+1:n),expected)"),'argv0=T\n',{27:'argument_zero_identity_from_input.f90\n'},features=['explicit input','logical argv0 identity','allocatable CHARACTER','LLE/LGE padding'])
# Preserve the independently written failing source. COUNT still has its
# earlier rank<=2 contract; this observation does not promote COUNT support.
for c in CASES:
 if c['name']=='character_cube_lexical_count':
  c.update(category='reject',expected_stdout='',gnu='compile',diagnostic='Array intrinsic requires a rank-one or rank-two array')
add('character_cube_lexical_position_output',program('integer::s\ncharacter(80)::line\ncharacter(2)::words(2,1,2)\nlogical::mask(2,1,2)',"line='\"a\" \"b\" \"b \" \"z\"'\nread(line,*,iostat=s)words\nif(s/=0)error stop 1\nmask=lge(words,'b')\nprint '(a,t6,4l1)','mask',mask"),'mask FTTT\n',features=['rank-three CHARACTER READ','rank-three LGE','T placement','rank-three output'])
locations={'character_cube_lexical_count':(11,32),'partial_internal_failure_no_new_output':(11,13),'unbound_input_after_query':(9,1),'bad_dynamic_dim_after_read':(11,17),'norm_overflow_after_pending_record':(6,14),'nonascii_lexical_output_atomic':(8,14),'position_cap_after_explicit_read':(8,1)}
for c in CASES:
 if c['name'] in locations:c['diagnostic_line'],c['diagnostic_column']=locations[c['name']]
(ROOT/'manifest.json').write_text(json.dumps(dict(schema=1,cases=CASES),indent=2)+'\n')
print(len(CASES))
