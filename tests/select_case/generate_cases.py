#!/usr/bin/env python3
"""Deterministic SELECT CASE / CHARACTER / array PARAMETER corpus."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parent
cases=[]
def add(name,body,want='',category='success',baseline='run',preamble='',full=None):
    source=full or 'program p\nimplicit none\n'+preamble+body+'\nend program p\n'
    (ROOT/'cases'/f'{name}.f90').write_text(source)
    cases.append(dict(name=name,source=f'cases/{name}.f90',category=category,baseline=baseline,expected_stdout=want))
def reject(name,body,preamble='',baseline='reject'):
    add(name,body,category='reject',baseline=baseline,preamble=preamble)
add('requested_sample','',full=(ROOT.parent.parent/'examples/select_case.f90').read_text(),want='''Integer selector:
 -3  negative
  0  zero
  2  between 1 and 3
  5  other positive integer
  6  4, 6, or 8
 10  between 9 and 12
 13  13 or greater
Character selector:
A primary color
Passing grade B-D
Logical selector:
Passed
Expression as selector:
Odd
''')
for n in [-100,-3,-1,0,1,2,3,4,5,6,8,9,10,12,13,100]:
    want='negative' if n<0 else 'zero' if n==0 else 'small' if n<4 else 'even' if n in [4,6,8] else 'medium' if 9<=n<=12 else 'large' if n>=13 else 'other'
    add(f'int_{n}'.replace('-','neg'),f'''n={n}
select case(n)
case default
print *, 'other'
case(:-1)
print *, 'negative'
case(0)
print *, 'zero'
case(1:3)
print *, 'small'
case(4,6,8)
print *, 'even'
case(9:12)
print *, 'medium'
case(13:)
print *, 'large'
end select''',want,preamble='integer::n\n')
for n in ['A','B','C','D','E','', 'A ', 'AA', 'Z']:
    want='excellent' if n.rstrip()=='A' else 'passing' if 'B'<=n<='D' else 'other'
    add('char_'+(n.replace(' ','blank') or 'empty'),f'''select case('{n}')
case('A')
print *,'excellent'
case('B':'D')
print *,'passing'
case default
print *,'other'
end select''',want)
add('char_open_ranges',"select case('abcd')\ncase(:'a')\nprint *,0\ncase('aa':)\nprint *,1\nend select",'1')
for n in ['true','false']:
    add('logical_'+n,f"select case(.{n}.)\ncase(.true.)\nprint *,1\ncase(.false.)\nprint *,0\nend select",'1' if n=='true' else '0')
add('no_match',"select case(20)\ncase(1:3)\nprint *,0\nend select\nprint *,1",'1')
add('empty_select',"select case(2)\nend select\nprint *,1",'1')
add('empty_bodies',"select case(2)\ncase(1)\ncase(2)\ncase default\nprint *,0\nend select\nprint *,1",'1')
add('reversed_range',"select case(3)\ncase(7:2)\nprint *,0\ncase(3)\nprint *,1\nend select",'1')
add('nested_select',"do i=1,2\nselect case(i)\ncase(1)\nselect case(.true.)\ncase(.true.)\nprint *,11\nend select\ncase default\nprint *,22\nend select\nend do",'11 22',preamble='integer::i\n')
add('char_assignment',"x='abcdef'\nprint '(a)',x\nx='q'\nprint '(a)',x\nprint *,x=='q',x<'r',x>='q',trim(x)\nx=''\nprint '(a)',trim(x)",'abc q T T T q',preamble='character(len=3)::x\n')
add('char_zero_length',"x='abc'\nprint *,x=='',trim(x)==''",'T T',preamble='character(0)::x\n')
add('char_default_length',"x='AB'\nprint *,x,trim(string=x)",'AA',preamble='character::x\n')
add('char_parameter',"select case(c)\ncase('abc')\nprint *,1\nend select",'1',preamble="character(3),parameter::c='abcdef'\n")
add('char_parameter_pad',"print *,c=='a'",'T',preamble="character(3),parameter::c='a'\n")
add('array_parameter_basic',"print *,a,size(a),sum(a),a(-1),b",'1 2 3 3 6 2 3',preamble='integer,parameter::a(-2:0)=[1,2,3]\ninteger,parameter::b=a(0)\n')
add('array_parameter_expr',"print *,b",'3 5 7',preamble='integer,parameter::a(3)=[1,2,3]\ninteger,parameter::b(3)=a*2+1\n')
add('array_parameter_section',"print *,b",'3 2 1',preamble='integer,parameter::a(3)=[1,2,3]\ninteger,parameter::b(3)=a(3:1:-1)\n')
add('array_parameter_scalar_expansion',"print *,a,sum(a)",'7 7 7 21',preamble='integer,parameter::a(3)=7\n')
add('array_parameter_rank_two',"print *,a,a(2,3),size(a),sum(a)",'2 2 2 2 2 2 2 6 12',preamble='integer,parameter::a(2,3)=2\n')
add('array_parameter_zero',"print *,size(a),sum(a)",'0 0',preamble='integer,parameter::a(0)=1\n')
add('array_parameter_real',"print *,sum(a),b",'3 1 2',preamble='real(8),parameter::a(2)=[1d0,2d0]\nreal,parameter::b(2)=a\n')
add('array_parameter_logical',"print *,a",'T F',preamble='logical,parameter::a(2)=[.true.,.false.]\n')
add('case_named_array_bound',"select case(2)\ncase(a(1):a(2))\nprint *,1\nend select",'1',preamble='integer,parameter::a(2)=[1,3]\n')
add('array_parameter_module', '', '3 4 7', full='''module m
implicit none
integer,parameter::a(2)=[3,4]
contains
integer function f() result(r)
r=sum(a)
end function
end module
program p
use m
implicit none
print *,a,f()
end program
''')
add('selector_once','', 'selector 2', full='''module m
implicit none
contains
impure elemental integer function f(x) result(r)
integer,intent(in)::x
print *,'selector'
r=x
end function
end module
program p
use m
implicit none
select case(f(2))
case(0)
print *,0
case(1)
print *,1
case(2)
print *,2
case default
print *,-1
end select
end program
''')
add('char_result','', 'ABC', full='''module m
implicit none
contains
function f(x) result(r)
character(len=*),intent(in)::x
character(len=3)::r
r=x
end function
end module
program p
use m
implicit none
print *,f('ABCDE')
end program
''')
add('char_mutable_dummy','', 'q', full='''module m
implicit none
contains
subroutine f(x)
character(len=*),intent(inout)::x
x='q'
end subroutine
end module
program p
use m
implicit none
character(3)::x
x='ABC'
call f(x)
print '(a)',x
end program
''')
for name,selector in [('real','1.0'),('array','[1,2]')]:
    reject('bad_selector_'+name,f'select case({selector})\ncase default\nend select')
for name,bounds in [('same','case(1)\ncase(1)'),('range','case(1:5)\ncase(5:7)'),('within','case(1:5)\ncase(3)'),('open','case(:1)\ncase(0:)'),('discrete','case(1,1)')]:
    reject('overlap_'+name,'select case(1)\n'+bounds+'\nend select')
reject('overlap_chars',"select case('a')\ncase('a')\ncase('a ')\nend select")
reject('overlap_logical','select case(.true.)\ncase(.false.)\ncase(.false.)\nend select')
reject('logical_range','select case(.true.)\ncase(.false.:.true.)\nend select')
reject('bad_bound_type','select case(1)\ncase(1.0)\nend select')
reject('bad_bound_rank','select case(1)\ncase([1,2])\nend select')
reject('nonconstant_bound','n=1\nselect case(1)\ncase(n)\nend select',preamble='integer::n\n')
reject('empty_range','select case(1)\ncase(:)\nend select')
reject('duplicate_default','select case(1)\ncase default\ncase default\nend select')
reject('bare_case','case(1)')
reject('code_before_case','select case(1)\nprint *,1\ncase(1)\nend select')
reject('parameter_write','a(1)=7',preamble='integer,parameter::a(2)=[1,2]\n')
reject('parameter_shape','print *,a',preamble='integer,parameter::a(3)=[1,2]\n')
reject('parameter_nonconstant','print *,b',preamble='integer::a(2)\ninteger,parameter::b(2)=a\n')
reject('trim_numeric','print *,trim(1)')
reject('trim_arity',"print *,trim('a','b')")
reject('trim_keyword',"print *,trim(wrong='a')")
add('bad_length_expr','x=\'a\'',preamble='integer,parameter::n=3\ncharacter(n)::x\n')
add('char_array','print *,x',preamble='character(3)::x(2)\n',category='runtime',baseline='compile')
add('formatted_padding',"x='abcdef'\nprint '(a)',x\nx='q'\nprint '(a)',x",'abc\nq  \n',preamble='character(3)::x\n')
cases[-1]['exact_stdout']=True
add('char_out_dummy','', 'abc', full='''module m
implicit none
contains
subroutine f(x)
character(len=*),intent(out)::x
x='abcdef'
end subroutine
end module
program p
use m
implicit none
character(3)::x
call f(x)
print '(a)',x
end program
''')
add('char_fixed_input','', 'AB', full='''module m
implicit none
contains
subroutine f(x)
character(2),intent(in)::x
print *,x
end subroutine
end module
program p
use m
implicit none
call f('ABCDE')
end program
''')
add('char_typed_result','', 'ABC', full='''module m
implicit none
contains
character(3) function f(x) result(r)
character(*),intent(in)::x
r=x
end function
end module
program p
use m
implicit none
print *,f('ABCDE')
end program
''')
add('char_fixed_writable_equal','', 'Z', full='''module m
implicit none
contains
subroutine f(x)
character(3),intent(inout)::x
x='Z'
end subroutine
end module
program p
use m
implicit none
character(3)::x
x='ABC'
call f(x)
print *,x
end program
''')
add('char_out_unwritten','', '',category='runtime',baseline='skip',full='''module m
implicit none
contains
subroutine f(x)
character(*),intent(out)::x
return
end subroutine
end module
program p
use m
implicit none
character(3)::x
x='ABC'
call f(x)
print *,x
end program
''')
add('selector_uninitialized','select case(x)\ncase default\nprint *,1\nend select','',category='runtime',baseline='skip',preamble='integer::x\n')
add('budgeted_select','select case(1)\ncase(1)\nprint *,1\nend select','',category='runtime',baseline='skip')
cases[-1]['args']=['--max-steps','1']
reject('case_zero_divisor','select case(1)\ncase(1/0)\nend select')
reject('array_parameter_section_bad_extent','print *,b',preamble='integer,parameter::a(3)=[1,2,3]\ninteger,parameter::b(2)=a(:)\n')
add('array_parameter_rank_two_section','print *,b','1 1 1 1',preamble='integer,parameter::a(2,2)=1\ninteger,parameter::b(2,2)=a(:,:)\n')
reject('named_select','outer:select case(1)\ncase(1) outer\nprint *,1\nend select outer',baseline='compile')
reject('character_kind','print *,x',preamble="character(kind=1,len=3)::x='abc'\n",baseline='compile')
reject('case_value_limit','select case(1)\n'+'\n'.join('case('+str(i)+')' for i in range(65))+'\nend select',baseline='compile')
cases[-1]['diagnostic']='CASE value/range limit exceeded'
cases[0]['exact_stdout']=True
(ROOT/'manifest.json').write_text(json.dumps({'cases':cases},indent=2)+'\n')
print(len(cases),'cases')
