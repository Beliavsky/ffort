#!/usr/bin/env python3
"""Focused, deterministic regressions for scope-aware expression actual typing."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parent

def source(expr='x**2',declarations='real(dp)::x(4)=[1d0,2d0,3d0,4d0]',dummy='real(dp)',dims=':',body='y=sum(v)/size(v)',before=''):
    return f'''module m
implicit none
integer,parameter::dp=kind(1d0)
contains
function probe(v) result(y)
{dummy},intent(in)::v({dims})
real(dp)::y
{body}
end function
end module
program p
use m
implicit none
{declarations}
{before}
print *,probe({expr})
end program
'''

def main():
    cases=[]; (ROOT/'cases').mkdir(exist_ok=True)
    def add(name,text,expected,category='success',baseline='run',**extra):
        path='cases/'+name+'.f90';(ROOT/path).write_text(text)
        cases.append(dict(name=name,source=path,expected_stdout=expected,category=category,baseline=baseline,rel_tol=1e-13,abs_tol=1e-13,**extra))
    original=(ROOT.parents[1]/'examples/mean_random_power.f90').read_text()
    add('user_exact_random_power',original,'R R',repeatable=True,random_moments=True,originating_message_id='Sentinel_073316d19ee88191bd372a023c4993d2')
    add('exact_analytic_constant',original.replace('call random_number(x)','x=0.5_dp'),'.5 .25')
    for label,expr,want in [
        ('integer_power','x**2','7.5'),('wide_integer_power','x**2_8','7.5'),
        ('unary_minus','-x','-2.5'),('scalar_multiply','x*2','5.0'),
        ('scalar_add','x+1','3.5'),('array_multiply','x*x','7.5'),
        ('nested_arithmetic','x**2+1','8.5'),('parenthesized','(x+1)**2','13.5'),
        ('reversed_section','x(4:1:-2)**2','10.0'),('nested_intrinsic','sqrt(x**2)','2.5'),
        ('absolute_value','abs(-x)','2.5'),('divide','x/2','1.25'),
        ('scalar_array_power','2**x','7.5'),('real_exponent','x**2.0_8','7.5'),
        ('keyword_expression','v=x**2','7.5'),('constructor_expression','[1d0,2d0,3d0]**2','4.666666666666667')]:
        add(label,source(expr),want)
    add('rank_two_power',source('a**2','real(dp)::a(-1:0,4:5)=2d0',dims=':,:'),'4.0')
    add('rank_reduced_section',source('a(:,j)**2','real(dp)::a(-1:0,4:5)=3d0\ninteger::j=5'),'9.0')
    add('empty_expression',source('x**2','real(dp)::x(0)',body='y=sum(v)'),'0.0')
    add('real32_wide_integer_exponent',source('x**2_8','real::x(2)=[2.,4.]',dummy='real'),'10.0')
    add('mixed_real_power_promotes',source('x**2.0_8','real::x(2)=[2.,4.]'),'10.0')
    add('scalar_subscript_result',source('x(2)**2','real(dp)::x(4)=3d0').replace('v(:)','v').replace('y=sum(v)/size(v)','y=v'),'9.0')
    for label,expr in [('power','x**2'),('wide_power','x**2_8'),('add','x+1'),('minus','-x'),('product','x*x'),('intrinsic','abs(x)')]:
        add('reject_real32_dummy_'+label,source(expr,dummy='real'),'','invalid','reject')
    add('reject_real32_actual',source('x**2','real::x(4)=1.0'),'','invalid','reject')
    add('reject_integer_dummy',source(dummy='integer'),'','invalid','reject')
    add('reject_rank_two_dummy',source(dims=':,:'),'','invalid','reject')
    add('reject_rank_two_actual',source('a**2','real(dp)::a(2,2)=1d0'),'','invalid','reject')
    add('reject_scalar_actual',source('x(2)**2'),'','invalid','reject')
    add('reject_known_shape_mismatch',source('x+y','real(dp)::x(4)=1d0,y(3)=2d0'),'','invalid','reject')
    add('runtime_section_shape_mismatch',source('x(1:n)+x(1:k)','real(dp)::x(4)=1d0\ninteger::n=3,k=4'),'','runtime','compile')
    add('runtime_uninitialized',source(declarations='real(dp)::x(4)'),'','runtime','compile')
    add('large_random_power',original.replace('x(1000)','x(100000)'),
        'R R',repeatable=True,random_moments=True)
    def integer_source(expr='a+1_8',kind=8,actual_kind=8,init='[1_8,2_8]'):
        return f"""module m
implicit none
contains
integer({kind}) function total(a) result(r)
integer({kind}),intent(in)::a(:)
r=sum(a)
end function
end module
program p
use m
implicit none
integer({actual_kind}),parameter::a(2)={init}
print *,total({expr})
end program
"""
    exact_integer=integer_source(init='[9007199254740993_8,2_8]').replace(
        'print *,total(a+1_8)', 'integer(8),parameter::b(2)=a+1_8\nprint *,total(b(:)),total(a+1_8)')
    add('wide_parameter_array_actual',exact_integer,'9007199254740997 9007199254740997')
    add('integer4_parameter_actual',integer_source('a+1',4,4,'[1,2]'),'5')
    add('integer4_plus_integer8',integer_source('a+1_8',8,4,'[1,2]'),'5')
    add('integer4_wide_power_exponent',integer_source('a**2_8',8,4,'[1,2]'),'5')
    add('integer8_power_exponent',integer_source('a**2',8,8),'5')
    add('integer8_reverse_expression',integer_source('a(2:1:-1)+1_8'),'5')
    add('reject_integer8_to_integer4',integer_source('a+1_8',4,8),'','invalid','reject')
    add('reject_integer4_to_integer8',integer_source('a+1',8,4,'[1,2]'),'','invalid','reject')
    add('reject_integer8_power_to_integer4',integer_source('a**2_8',4,4,'[1,2]'),'','invalid','reject')
    add('wide_rank_two_reduction_actual',integer_source('sum(a,dim=1)',8,8).replace(
        'a(2)=[1_8,2_8]','a(2,2)=9007199254740993_8'),'36028797018963972')
    (ROOT/'manifest.json').write_text(json.dumps(dict(cases=cases),indent=2)+'\n')
    print('Generated',len(cases),'expression actual cases')
if __name__=='__main__':main()
