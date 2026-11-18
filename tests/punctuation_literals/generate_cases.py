from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parent;R.mkdir(exist_ok=True);cases=[]
def put(name,source,expected='',kind='pass',gnu='pass'):
 b=source.encode();(R/(name+'.f90')).write_bytes(b);cases.append(dict(name=name,kind=kind,gnu_compile=gnu,stdout=expected,sha256=hashlib.sha256(b).hexdigest()))
def program(body,decl=''):return 'program p\nimplicit none\n'+decl+'\n'+body+'\nend program\n'
strings=['[',']','(',')','/',',',':','::','%','=','=>','+','-','//','**','.not.','.flip.','"',"'",'']
for n,t in enumerate(strings):
 q="'"+t.replace("'","''")+"'";ident=str(n).zfill(2)
 put('scalar_'+ident,program("print '(a)',"+q),t+'\n')
 put('group_'+ident,program("print '(a)',("+q+")"),t+'\n')
 put('actual_'+ident,program("print '(i0)',len("+q+")"),str(len(t))+'\n')
 put('typed_array_'+ident,program("print '(a)',[character(3)::"+q+"]"),t[:3].ljust(3)+'\n')
put('untyped_array',program("print '(a)', ['[',']','(',')','/',',',':','%']"),'[\n]\n(\n)\n/\n,\n:\n%\n')
put('slash_constructor',program("print '(a)', (/ character(3)::'/',')','[',']' /)"),' /'.strip().ljust(3)+'\n'+')  \n[  \n]  \n')
put('substring',program("print '(a)', '['(1:1),'('(1:1),'/'(1:1),']'(1:1)"),'[\n(\n/\n]\n')
put('concat_wrap',program("s='ab'\nprint '(a)','['//s//']'\nprint '(a)','('//s//')'",'character(2)::s'),'[ab]\n(ab)\n')
put('structure_actual',"module boxes\nimplicit none\ntype :: box\ncharacter::c\nend type\nend module\nprogram p\nuse boxes\nimplicit none\ntype(box)::b\nb=box(')')\nprint '(a)',b%c\nend program\n",'','reject','pass')
put('actual_syntax',program("print '(i0)', -(1+2), +4, size([1,2]), size((/1,2/))"),'-3\n4\n2\n2\n')
put('named_literal_formats',program("s='[x]'\nprint fmt,s\nwrite(*,'(a)') '('//s//')'", "character(*),parameter::fmt='(a)'\ncharacter(3)::s"),'[x]\n([x])\n')
put('defined_plus', '''module m
implicit none
interface operator(+)
module procedure f
end interface
contains
function f(a,b) result(c)
character(*),intent(in)::a,b
character(len(a)+len(b))::c
c=a//b
end function
end module
program p
use m
implicit none
character(2)::s
s='ab'
print '(a)','['+s+']'
end program
''','[ab]\n')
for name,body in [
 ('pseudo_plus',"print '(a)', 'a' '+' 'b'"),
 ('pseudo_concat',"print '(a)', 'a' '//' 'b'"),
 ('pseudo_comma',"print '(a)', 'a' ',' 'b'"),
 ('pseudo_open',"print '(a)', '(' 'a' ')'"),
 ('pseudo_format_separator',"print '(a)' ',' '['"),
 ('pseudo_close_actual',"print *,len('a' ')'"),
 ('pseudo_close_group',"print *, (1 ')'") ,
 ('missing_close',"print *, (1+2"),
 ('missing_array_close',"print *, [1,2"),
 ('trailing_array_comma',"print *, [character(1)::'a',]"),
 ('actual_unary_character',"print *, + '['"),
 ('actual_unary_missing',"print *, +"),
]:put(name,program(body),'','reject','fail' if name!='trailing_array_comma' else 'fail')
(R/'manifest.json').write_text(json.dumps(dict(cases=cases),indent=2)+'\n');print(len(cases))
