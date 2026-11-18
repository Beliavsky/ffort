from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parent;cases=[]
orig=(R/'original_module.f90.inc').read_bytes()
def put(name,source,kind='pass',gnu='pass',diagnostic='',stdout=None):
 b=source if isinstance(source,bytes) else source.encode();(R/(name+'.f90')).write_bytes(b)
 c=dict(name=name,kind=kind,gnu_compile=gnu,sha256=hashlib.sha256(b).hexdigest())
 if diagnostic:c['diagnostic_contains']=diagnostic
 if stdout is not None:c['stdout']=stdout
 cases.append(c)
def program(body,decl='',use='use original_character_plus'):
 return orig+f'program p\n{use}\nimplicit none\n{decl}\n{body}\nend program\n'.encode()
def mod(fn,body,decl='',spec='f',prefix='',use='use m',operator='+'):
 return f'module m\nimplicit none\n{prefix}\ninterface operator({operator})\nmodule procedure {spec}\nend interface\ncontains\n{fn}\nend module\nprogram p\n{use}\nimplicit none\n{decl}\n{body}\nend program\n'
cc='elemental function f(a,b) result(c)\ncharacter(*),intent(in)::a,b\ncharacter(len(a)+len(b))::c\nc=a//b\nend function'
ci='elemental function f(a,b) result(c)\ncharacter(*),intent(in)::a\ninteger,intent(in)::b\ninteger::c\nc=len(a)+b\nend function'
put('original_closure',(R/'original_closure.f90').read_bytes(),stdout='abc   |6\nrow_12                   |25\n|0\nrow_0                    |\nx_-7                     |\n q_2147483647            |\n a x  |\nby    |\nv_4!\nx_-123\np-0007              |\n7\n')
for name,body,decl in [
 ('scalar_char','print \'(a,"|",i0)\'," ab "+" c ",len(" ab "+" c ")',''),
 ('zero_lengths','print \'(a,"|",i0)\',""+"",len(""+"")',''),
 ('integer_limits','print \'(a)\',trim("v"+(-2147483647)),trim("v"+2147483647)',''),
 ('precedence_left','print \'(a)\',trim("v"+1+2),trim("v"+(1+2)),trim("v"+2*3)',''),
 ('concatenation_precedence','print \'(a)\',trim("a"//"b"+2),trim("a"+2//"b")',''),
 ('dotted_unchanged','print \'(a)\',trim("q" .plus. -7)',''),
 ('numeric_unchanged','print \'(i0,1x,f5.1)\',2+3*4,1.5+2.0',''),
 ('rank1','a=[character(2)::"a","bb"," c"]\nprint \'(a,"|")\',a+[1,-2,3]','character(2)::a(3)'),
 ('rank2','a=reshape([character(2)::"a","b","c","d"],[2,2])\nprint \'(a,"|")\',a+reshape([1,2,3,4],[2,2])','character(2)::a(2,2)'),
 ('rank3','a="z"\nb=1\nprint \'(a,"|")\',a+b','character(1)::a(2,2,2)\ninteger::b(2,2,2)'),
 ('scalar_expansion','print \'(a,"|")\',"x"+[1,2,3]',''),
 ('reverse_section','a=[character(2)::"a","b","c"]\nprint \'(a,"|")\',a(3:1:-1)+[1,2,3]','character(2)::a(3)'),
 ('alias_snapshot','a=[character(4)::"a","b","c"]\na=a(3:1:-1)+[1,2,3]\nprint \'(a,"|")\',a','character(4)::a(3)'),
 ('padding_truncation','s="a"+2\nprint \'(a,"|")\',s\nt="long"+22\nprint \'(a,"|")\',t','character(8)::s\ncharacter(3)::t'),
 ('empty_array','a=""\nprint \'(i0)\',size(a+1)','character(3)::a(0)'),
 ('empty_rank3','a=""\nprint \'(i0)\',size(a+1)','character(3)::a(0,2,2)'),
 ('optional_generic_keywords','print \'(a,"|")\',str(-3),str(-3,prefix="p"),str(prefix="p",ndigits=3,i=-3)',''),
 ('optional_generic_array','print \'(a,"|")\',str([1,-2,3],prefix="p")',''),
]:put(name,program(body,decl))
put('noncharacter_integer_result',mod(ci,"print '(i0)', 'abc'+7"),stdout='10\n')
put('noncharacter_real8_result',mod(ci.replace('integer::c','real(8)::c').replace('c=len(a)+b','c=real(len(a)+b,8)'),"print '(f8.2)', 'abc'+7"),stdout='   10.00\n')
put('noncharacter_logical_result',mod(ci.replace('integer::c','logical::c').replace('c=len(a)+b','c=len(a)==b'),"print '(l1)', 'abc'+3"),stdout='T\n')
put('character_real_operand',mod(ci.replace('integer,intent(in)::b','real(8),intent(in)::b').replace('c=len(a)+b','c=len(a)+int(b)'),"print '(i0)', 'abc'+7d0"),stdout='10\n')
put('character_logical_operand',mod(ci.replace('integer,intent(in)::b','logical,intent(in)::b').replace('c=len(a)+b','c=len(a)\nif(b)c=c+1'),"print '(i0)', 'abc'+.true."),stdout='4\n')
put('reverse_declared',mod(ci.replace('f(a,b)','f(b,a)'),"print '(i0)', 7+'abc'"),stdout='10\n')
put('kind8_declared',mod(ci.replace('integer,intent(in)::b','integer(8),intent(in)::b').replace('c=len(a)+b','c=len(a)+int(b)'),"print '(i0)', 'abc'+7_8"),stdout='10\n')
put('public_operator_private_specific',mod(ci,"print '(i0)', 'abc'+7",prefix='private\npublic::operator(+)'),stdout='10\n')
put('only_operator',mod(ci,"print '(i0)', 'abc'+7",use='use m,only:operator(+)'),stdout='10\n')
put('host_private_operator',mod(ci+'\ninteger function host() result(y)\ny="abc"+7\nend function',"print '(i0)',host()",spec='f',prefix='private\npublic::host',use='use m,only:host'),stdout='10\n')
put('elemental_nonchar_result',mod(ci,"print '(i0)', 'abc'+[1,2,3]"),stdout='4\n5\n6\n')
put('array_signature',mod('function f(a,b) result(c)\ncharacter(*),intent(in)::a(:)\ninteger,intent(in)::b\ninteger::c\nc=size(a)+b\nend function',"print '(i0)', [character(2)::'a','b']+7"),stdout='9\n')
for name,source,gnu,diag in [
 ('missing_operator',"program p\nprint *, 'a'+'b'\nend program\n",'fail','operator'),
 ('missing_reverse',program("print *, 1+'a'"),'fail','operator'),
 ('wrong_kind',program("print *, 'a'+1_8"),'fail','operator'),
 ('wrong_rank',mod(ci.replace('elemental ','').replace('::a','::a(:)'),"print *, 'a'+1"),'fail','operator'),
 ('private_operator',mod(ci,"print *, 'a'+1",prefix='private\npublic::f'),'fail','operator'),
 ('only_excluded',mod(ci,"print *, 'a'+1",use='use m,only:f'),'fail','operator'),
 ('numeric_override',mod(ci.replace('character(*),intent(in)::a','integer,intent(in)::a').replace('len(a)','a'),"print *,1+2"),'fail','Intrinsic-symbol'),
 ('unary_character',mod('function f(a) result(c)\ncharacter(*),intent(in)::a\ncharacter(len(a))::c\nc=a\nend function',"print *, +'a'"),'pass','two operands'),
 ('other_symbol',mod(cc,"print *, 'a'-'b'",operator='-'),'pass','Intrinsic-symbol'),
 ('optional_operator',mod(ci.replace('integer,intent(in)::b','integer,optional,intent(in)::b'),"print *, 'a'+1"),'pass','OPTIONAL'),
 ('out_operator',mod(ci.replace('elemental ','').replace('integer,intent(in)::b','integer,intent(out)::b'),"print *, 'a'+1"),'fail','INTENT'),
 ('duplicate_signature',mod(ci+'\n'+ci.replace(' f(',' g('),'print *,1',spec='f,g'),'fail','Duplicate'),
 ('generic_missing_required',program('print *,str(prefix="p")'),'fail','generic'),
 ('generic_unknown_keyword',program('print *,str(1,unknown=2)'),'fail','generic'),
 ('generic_duplicate_keyword',program('print *,str(1,i=2)'),'fail','generic'),
 ('generic_wrong_type',program('print *,str(.true.)'),'fail','generic'),
 ('generic_wrong_kind',program('print *,str(1_8)'),'fail','generic'),
]:put(name,source,'reject',gnu,diag)
put('minimum_integer_overflow',program("i=-2147483647-1\nprint '(a)',trim('v'+i)",'integer::i'),'runtime','pass','overflow')
# Shape mismatch is legal source, but caller arrays have dynamic sizes.
put('runtime_shape',program("a='x'\nb=[1,2]\nprint '(a)',a+b",'character(1),allocatable::a(:)\ninteger,allocatable::b(:)').replace(b"a='x'",b"allocate(a(3))\na='x'"),'runtime','pass','shape')
# Named generic omission uses exact declared OPTIONAL positions, not trailing truncation.
gen='''module gmod
implicit none
interface choose
module procedure f
end interface
contains
integer function f(a,b,c) result(r)
integer,optional,intent(in)::a,b
integer,intent(in)::c
r=c
if(present(a))r=r+10*a
if(present(b))r=r+100*b
end function
end module
program p
use gmod
implicit none
BODY
end program
'''
put('optional_middle_keyword',gen.replace('BODY',"print '(i0)',choose(c=3),choose(2,c=3),choose(c=3,b=2,a=1)"),stdout='3\n23\n213\n')
put('optional_all_zero_actuals',gen.replace('integer,intent(in)::c','integer,optional,intent(in)::c').replace('r=c','r=0\nif(present(c))r=c').replace('BODY',"print '(i0)',choose()"),stdout='0\n')
for case in cases:
 if case['name']=='alias_snapshot':
  case['stdout']='c_1 |\nb_2 |\na_3 |\n';case['gnu_o0_discrepancy']='c_1 |\n_2  |\n_3  |\n'
(R/'manifest.json').write_text(json.dumps(dict(cases=cases),indent=2)+'\n')
print(len(cases))
