from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parent
CASES=[]
def add(name,source,out='',category='success',gnu='run',**kw):
 p=ROOT/'cases'/(name+'.f90');p.write_text(source.lstrip('\n'))
 c=dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),category=category,gnu=gnu,expected_stdout=out)
 if category!='success':c.update(diagnostic='PENDING',diagnostic_line=1,diagnostic_column=1)
 c.update(kw);CASES.append(c)
def wrap(components,body,decl='type(dt)::x\n',pre='',procedures=''):
 return 'module types\nimplicit none\n'+pre+'type::dt\n'+components+'\nend type\n'+('contains\n'+procedures if procedures else '')+'end module\nprogram p\nuse types\nimplicit none\n'+decl+body+'\nend program\n'
add('exact_user','''module statistics_mod
implicit none
type :: dt
real :: y=1000.0
end type dt
end module
use statistics_mod
implicit none
type(dt)::x
print*,x%y
end
''','1000.0\n',numeric_lines=[0])
mixed='integer::a=7\nreal(8)::b=1.25d0\nlogical::ok=.true.'
show="print '(i3,f6.2,l2)',x%a,x%b,x%ok"
add('mixed_scalar_defaults',wrap(mixed,show),'  7  1.25 T\n')
add('empty_constructor_defaults',wrap(mixed,'x=dt()\n'+show),'  7  1.25 T\n')
add('trailing_default_omission',wrap(mixed,'x=dt(9)\n'+show),'  9  1.25 T\n')
add('explicit_constructor_override',wrap(mixed,'x=dt(9,2.5d0,.false.)\n'+show),'  9  2.50 F\n')
add('intrinsic_copy_independent',wrap('real::y=1000.0',"z=x\nz%y=2.5\nprint '(2f8.1)',x%y,z%y",'type(dt)::x,z\n'),'  1000.0     2.5\n')
add('component_override',wrap('real::y=1000.0',"x%y=12.5\nprint '(f6.1)',x%y"),'  12.5\n')
add('mixed_defined_component_access',wrap('integer::a=7\ninteger::b',"print '(i0)',x%a"),'7\n')
add('undefined_component_guard',wrap('integer::a=7\ninteger::b',"print '(a)','SAFE'\nprint '(i0)',x%b"),'SAFE\n','runtime','compile')
add('partial_record_copy_boundary',wrap('integer::a=7\ninteger::b',"print '(a)','SAFE'\nz=x\nprint '(i0)',z%a",'type(dt)::x,z\n'),'SAFE\n','runtime','compile')
add('fresh_procedure_local',wrap('integer::a=7','call show()\ncall show()',decl='',procedures='''subroutine show()
type(dt)::x
print '(i0)',x%a
x%a=99
end subroutine
'''),'7\n7\n')
add('default_function_result',wrap('integer::a=7',"x=make()\nprint '(i0)',x%a",procedures='''function make() result(r)
type(dt)::r
end function
'''),'7\n')
add('pure_default_function_result',wrap('integer::a=7',"x=make()\nprint '(i0)',x%a",procedures='''pure function make() result(r)
type(dt)::r
end function
'''),'7\n')
add('intent_out_resets_defaults',wrap('integer::a=7',"x%a=99\ncall reset(x)\nprint '(i0)',x%a",procedures='''subroutine reset(v)
type(dt),intent(out)::v
print '(i0)',v%a
end subroutine
'''),'7\n7\n')
add('intent_inout_preserves_value',wrap('integer::a=7',"x%a=99\ncall change(x)\nprint '(i0)',x%a",procedures='''subroutine change(v)
type(dt),intent(inout)::v
v%a=v%a+1
end subroutine
'''),'100\n')
add('intent_in_preserves_value',wrap('integer::a=7',"x%a=99\ncall show(x)\nprint '(i0)',x%a",procedures='''subroutine show(v)
type(dt),intent(in)::v
print '(i0)',v%a
end subroutine
'''),'99\n99\n')
add('recursive_local_lifetime',wrap('integer::a=7','call show(2)',decl='',procedures='''recursive subroutine show(n)
integer,intent(in)::n
type(dt)::v
print '(i0)',v%a
v%a=n
if(n>0)call show(n-1)
print '(i0)',v%a
end subroutine
'''),'7\n7\n7\n0\n1\n2\n')
add('signed_zero_default',wrap('real(8)::a=-0.0d0',"print '(es25.17)',x%a"),'-0.0\n',numeric_lines=[0])
add('parameter_and_intrinsic_defaults',wrap('integer(8)::a=abs(n)+3_8\nreal(8)::b=real(n,8)/2.0d0',"print '(i4,f8.1)',x%a,x%b",pre='integer(8),parameter::n=-11_8\n'),'  14    -5.5\n')
add('missing_required_constructor_component',wrap('integer::a=7\ninteger::b',"x=dt()"),category='reject',gnu='known-reject',gnu_compile_diagnostic='No initializer')
add('trailing_missing_component',wrap('integer::a=7\ninteger::b\ninteger::c=9',"x=dt(2)"),category='reject',gnu='known-reject',gnu_compile_diagnostic='No initializer')
add('provided_required_uses_trailing_default',wrap('integer::a=7\ninteger::b\ninteger::c=9',"x=dt(2,4)\nprint '(3i3)',x%a,x%b,x%c"),'  2  4  9\n')
add('mutable_initializer_rejected',wrap('integer::a=n','',pre='integer::n\n'),category='reject',gnu='known-reject',gnu_compile_diagnostic='constant expression')
add('mismatched_logical_initializer',wrap('logical::a=3',''),category='reject',gnu='known-reject',gnu_compile_diagnostic='Cannot convert')
add('zero_divisor_default',wrap('integer::a=1/0',''),category='reject',gnu='known-reject',gnu_compile_diagnostic='Division by zero')
add('array_component_boundary',wrap('integer::a(2)=7',''),category='reject',gnu='compile')
add('character_component_boundary',wrap("character(2)::a='ok'",''))
add('multiple_initialized_entities_boundary',wrap('integer::a=1,b=2',''))
add('keyword_constructor_boundary',wrap('integer::a=7',"x=dt(a=8)"),category='reject',gnu='compile')
add('main_local_type_boundary','''program p
implicit none
type::dt
integer::a=7
end type
type(dt)::x
print '(i0)',x%a
end program
''',category='reject',gnu='compile')
# Keep the empty-result sources unchanged. GNU14.2 produces a value other
# than the language-mandated default; separate profile evidence records this.
for c in CASES:
 if c['name'] in ('default_function_result','pure_default_function_result'):
  c['gnu']='compile'
  c['oracle_limitation']='GNU14.2 empty default-initialized result body disagreement; independent language default expected, not execution agreement'
add('function_result_read_default',wrap('integer::a=7',"x=make()\nprint '(i0)',x%a",procedures='''function make() result(r)
type(dt)::r
r%a=r%a+0
end function
'''),'7\n')
add('pure_function_result_override',wrap('integer::a=7',"x=make()\nprint '(i0)',x%a",procedures='''pure function make() result(r)
type(dt)::r
r%a=11
end function
'''),'11\n')
add('intent_out_undefined_other',wrap('integer::a=7\ninteger::b',"x%b=99\ncall reset(x)",procedures='''subroutine reset(v)
type(dt),intent(out)::v
print '(i0)',v%a
print '(i0)',v%b
end subroutine
'''),'7\n','runtime','compile')
add('constant_conversion',wrap('integer::a=3.75d0\nreal(8)::b=7_8\nlogical::ok=.not..false.',show),'  3  7.00 T\n')
add('constant_logical_expression',wrap('logical::ok=(3<4).and..true.',"print '(l1)',x%ok"),'T\n')
add('default_constructor_argument',wrap('integer::a=7',"call show(dt())",decl='',procedures='''subroutine show(v)
type(dt),intent(in)::v
print '(i0)',v%a
end subroutine
'''),'7\n')
add('constructor_numeric_conversion',wrap('integer::a=7\nreal(8)::b=2.0d0',"x=dt(4.75,9)\nprint '(i3,f5.1)',x%a,x%b"),'  4  9.0\n')
add('real_kind_eight_default',wrap('real(8)::a=1.5d0',"print '(f6.2)',x%a"),'  1.50\n')
add('integer_kind_eight_default',wrap('integer(8)::a=3000000000_8',"print '(i0)',x%a"),'3000000000\n')
add('negative_zero_constructor_override',wrap('real(8)::a=1.0d0',"x=dt(-0.0d0)\nprint '(es25.17)',x%a"),'-0.0\n',numeric_lines=[0])
add('imported_parameter_default','''module constants
implicit none
integer,parameter::n=23
end module
module types
use constants,only:n
implicit none
type::dt
integer::a=n
end type
end module
program p
use types
implicit none
type(dt)::x
print '(i0)',x%a
end program
''','23\n')
add('two_distinct_types','''module types
implicit none
type::first
integer::a=7
end type
type::second
integer::a=9
end type
end module
program p
use types
implicit none
type(first)::x
type(second)::y
print '(2i2)',x%a,y%a
end program
''',' 7 9\n')
add('anonymous_without_default','''module types
implicit none
type::dt
real::y
end type
end module
use types
implicit none
type(dt)::x
x%y=42.0
print '(f5.1)',x%y
end
''',' 42.0\n')
add('anonymous_intrinsic_local','''module constants
implicit none
integer,parameter::n=12
end module
use constants
implicit none
integer::x
x=n+3
print '(i0)',x
end
''','15\n')
add('integer_default_overflow',wrap('integer::a=2147483647+1',''),category='reject',gnu='compile')
add('real_default_overflow',wrap('real::a=huge(1.0)*2.0',''),category='reject',gnu='compile')
add('array_constructor_default_boundary',wrap('integer::a=sum([1,2])',''),category='reject',gnu='compile')
for c in CASES:c.update(json.loads((ROOT/'diagnostics.json').read_text()).get(c['name'],{}))
(ROOT/'manifest.json').write_text(json.dumps(dict(cases=CASES),indent=2)+'\n')
(ROOT/'SOURCE-IDENTITY.json').write_text(json.dumps(dict(sources=[dict(name=c['name'],file=c['source'],sha256=c['sha256']) for c in CASES]),indent=2)+'\n')
print(len(CASES))
