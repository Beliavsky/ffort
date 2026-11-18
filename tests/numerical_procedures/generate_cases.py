#!/usr/bin/env python3
"""Regenerate cases and independent Python math reference expectations."""
from pathlib import Path
import json, math
root=Path(__file__).resolve().parent
suite=root; cases=suite/'cases'; cases.mkdir(parents=True, exist_ok=True)
bs=(root.parent.parent/'examples/black_scholes.f90').read_text().rstrip()+'\n'
sub=(root.parent.parent/'examples/module_subroutine.f90').read_text().rstrip()+'\n'
module=bs.split('program test_black_scholes')[0]
manifest=[]
def add(name, source, expected='', category='success', baseline='run', diagnostic=None, **kw):
    file=f'cases/{name}.f90'
    (suite/file).write_text(source.strip()+'\n')
    row=dict(name=name,source=file,category=category,baseline=baseline,expected_stdout=str(expected))
    if diagnostic: row['diagnostic']=diagnostic
    row.update(kw); manifest.append(row)
def prog(body,decl='',uses='',internal=''):
    return f'program main\n{uses}\nimplicit none\n{decl}\n{body}\n'+('contains\n'+internal+'\n' if internal else '')+'end program main\n'
def mp(body, main, decl='', uses='use m'):
    return f'module m\nimplicit none\n{decl}\ncontains\n{body}\nend module m\n'+prog(main,uses=uses)
def typed_function(body='r=x*2.0_dp',name='twice',prefix='',typ='real(dp)',args='x',decl='real(dp), intent(in) :: x'):
    return f'{prefix}{typ} function {name}({args}) result(r)\n{decl}\n{body}\nend function {name}'
def bsource(body):
    return module+prog(body,uses='use black_scholes_module, only : dp, black_scholes_price')
def bsoracle(s,k,r,v,t):
    kd=k*math.exp(-r*t)
    if t==0: return max(s-k,0),max(k-s,0)
    if v==0: return max(s-kd,0),max(kd-s,0)
    d1=(math.log(s/k)+(r+.5*v*v)*t)/(v*math.sqrt(t)); d2=d1-v*math.sqrt(t)
    N=lambda x:.5*math.erfc(-x/math.sqrt(2))
    return s*N(d1)-kd*N(d2),kd*N(-d2)-s*N(-d1)
add('exact_black_scholes',bs,'''At the money
  Call:           10.4505835722
  Put:             5.5735260223
  Parity error:   0.0000E+00
In the money call
  Call:           23.6721907852
  Put:             2.1833847455
  Parity error:  -7.1054E-15
Zero volatility
  Call:            0.4678840160
  Put:             0.0000000000
  Parity error:   0.0000E+00
At expiration
  Call:            0.0000000000
  Put:             5.0000000000
  Parity error:   0.0000E+00
All put-call parity and benchmark tests passed.''',rel_tol=1e-12,abs_tol=1e-11)
add('exact_module_subroutine',sub,'twice 2.29999995 is 4.59999990')
fixtures=[('benchmark',100,100,.05,.2,1),('itm_call',120,100,.03,.3,.5),('zero_vol_itm',100,110,.05,0,2),('expiry_otm',95,100,.05,.2,0),('expiry_itm',105,100,.05,.2,0),('expiry_atm',100,100,.05,.2,0),('zero_both',100,110,-.05,0,0),('zero_vol_otm',95,100,0,0,1),('zero_vol_atm',100,100,0,0,1),('negative_rate',100,100,-.1,.2,2),('tiny_maturity',100,100,.01,.2,1e-12),('large_maturity',100,120,.02,.15,50),('large_vol',100,100,.01,4,1),('tiny_vol',100,100,0,1e-8,1),('deep_itm',1000,1,.03,.2,1),('deep_otm',1,1000,.03,.2,1),('small_scale',1e-4,1.1e-4,.03,.2,1),('large_scale',1e9,1.1e9,.03,.2,1)]
for i,(label,s,k,r,v,t) in enumerate(fixtures):
    call,put=bsoracle(s,k,r,v,t)
    actual=', '.join(f'{float(x):.17g}_dp' if '.' in f'{float(x):.17g}' or 'e' in f'{float(x):.17g}' else f'{float(x):.1f}_dp' for x in (s,k,r,v,t))
    body=f'''real(dp) :: c, p, expected, tolerance
c=black_scholes_price({actual}, .true.)
p=black_scholes_price({actual}, .false.)
expected={s:.17e}_dp - {k:.17e}_dp*exp(-({r:.17e}_dp)*{t:.17e}_dp)
tolerance=1.0e-12_dp*max(1.0_dp,abs(c),abs(p),abs(expected))
if(abs(c-p-expected)>tolerance) error stop 'parity'
print *,c,p'''
    # Declaration is deliberately placed before all executable statements.
    add('bs_'+label,bsource(body),f'{call:.17g} {put:.17g}',rel_tol=2e-12,abs_tol=2e-11)
for label,vals,msg in [('zero_spot',(0,100,.05,.2,1),'Spot and strike'),('negative_spot',(-1,100,.05,.2,1),'Spot and strike'),('zero_strike',(100,0,.05,.2,1),'Spot and strike'),('negative_strike',(100,-1,.05,.2,1),'Spot and strike'),('negative_volatility',(100,100,.05,-.2,1),'Volatility and maturity'),('negative_maturity',(100,100,.05,.2,-1),'Volatility and maturity')]:
    actual=', '.join(f'{float(x):.1f}_dp' for x in vals)
    add('bs_'+label,bsource(f'print *,black_scholes_price({actual}, .true.)'),category='runtime',baseline='runtime',diagnostic=msg)
uses='use, intrinsic :: iso_fortran_env, only : real64'
dp='integer, parameter :: dp=real64'
add('real64_precision',prog('x=1.0_dp+1.0e-12_dp\nprint *,x-1.0_dp',decl=dp+'\nreal(dp) :: x',uses=uses),'1.000088900582341e-12',rel_tol=1e-12,abs_tol=1e-20)
add('real64_intrinsics',prog('print *,exp(1.0_dp),log(2.0_dp),sqrt(2.0_dp),erfc(1.0_dp),abs(-2.0_dp)\nprint *,max(-5.0_dp,1.0_dp,3.0_dp,2.0_dp)',decl=dp,uses=uses),' '.join(map(repr,[math.e,math.log(2),math.sqrt(2),math.erfc(1),2.,3.])),rel_tol=1e-12,abs_tol=1e-14)
add('real64_arithmetic',prog('print *,2.0_dp**(-3),3.0_dp/2.0_dp,1.0_dp+2.0_dp*3.0_dp,(-2.0_dp)**3',decl=dp,uses=uses),'0.125 1.5 7 -8',rel_tol=1e-12,abs_tol=1e-14)
add('real32_unaffected',prog('x=1.0+1.0e-8\nprint *,x-1.0',decl='real :: x'),'0')
add('real64_assignment_converts',prog("a=1.0_dp/3.0_dp\nb=a\nc=b\nprint '(3es24.16)',a,b,c",decl=dp+'\nreal(dp) :: a,c\nreal :: b',uses=uses),'0.3333333333333333 0.3333333432674408 0.3333333432674408',rel_tol=1e-12,abs_tol=1e-14)
add('real64_typed_pure_function',mp(typed_function(prefix='pure '),'print *,twice(2.3_dp)',decl='integer, parameter :: dp=8'),'4.6',rel_tol=1e-12,abs_tol=1e-14)
add('real64_parameter_expression',mp(typed_function(),'print *,twice(2.3_dp)',decl='integer, parameter :: rk=8\ninteger, parameter :: dp=rk'),'4.6',rel_tol=1e-12,abs_tol=1e-14)
add('subroutine_repeated_frames',mp('''subroutine report(x)
real, intent(in) :: x
real :: a
a=x*2
print *,a
end subroutine report''','call report(1.0)\ncall report(2.0)\ncall report(1.0)'),'2 4 2')
add('subroutine_nested_call',mp('''subroutine first(x)
real, intent(in) :: x
call second(x*2)
print *,x
end subroutine first
subroutine second(x)
real, intent(in) :: x
print *,x
end subroutine second''','call first(3.0)'),'6 3')
add('subroutine_zero_arguments',mp('subroutine report()\nprint *,7\nend subroutine report','call report()'),'7')
add('subroutine_early_return',mp('''subroutine report(x)
integer, intent(in) :: x
if(x<0) then
print *,1
return
end if
print *,2
end subroutine report''','call report(-1)\ncall report(0)'),'1 2')
add('function_early_return',mp('''integer function f(x) result(y)
integer, intent(in) :: x
if(x<0) then
y=10
return
end if
y=20
end function f''','print *,f(-1),f(0)'),'10 20')
add('internal_character_subroutine',prog("call label('first')\ncall label('second')",internal='''subroutine label(s)
character(len=*), intent(in) :: s
print '(a)',s
end subroutine label'''),'first\nsecond',compare_mode='lines')
add('internal_module_function_call',mp(typed_function(),'call report(2.0_dp)',decl='integer, parameter :: dp=8').replace('end program main','contains\nsubroutine report(x)\nreal(dp), intent(in) :: x\nprint *,twice(x)\nend subroutine report\nend program main'),'4')
add('private_sibling_function',mp('''real function outer(x) result(y)
real, intent(in) :: x
y=inner(x)
end function outer
pure real function inner(x) result(y)
real, intent(in) :: x
y=x*2
end function inner''','print *,outer(2.5)',decl='private\npublic :: outer'),'5')
add('only_function_and_parameter',mp(typed_function(),'print *,twice(2.5_dp)',decl='integer, parameter :: dp=8',uses='use m, only : dp, twice'),'5')
add('formatted_a_f_es',prog("print '(a)', 'heading'\nprint '(a,f16.10)', '  Number: ', 1.25_dp\nprint '(a,es12.4)', '  Small: ',0.00125_dp",decl='integer, parameter :: dp=8'),'heading\n  Number:     1.2500000000\n  Small:   1.2500E-03',compare_mode='lines')
add('string_escaped_quotes',prog("print '(a)', 'It''s quoted'\nprint '(a)',\"say \"\"yes\"\"\""),'''It's quoted
say "yes"''',compare_mode='lines')
add('error_stop_character',prog("print '(a)','before'\nerror stop 'explicit test failure'\nprint *,999"),'before',category='runtime',baseline='runtime',diagnostic='explicit test failure')
add('error_stop_conditional_false',prog("if (.false.) error stop 'wrong'\nprint *,123"),'123')
add('error_stop_conditional_true',prog("if (.true.) error stop 'true branch'\nprint *,123"),'',category='runtime',baseline='runtime',diagnostic='true branch')
add('real64_sqrt_domain',prog('print *,sqrt(-1.0_dp)',decl='integer, parameter :: dp=8'),'',category='runtime',baseline='skip')
add('real64_log_domain',prog('print *,log(x)',decl='integer, parameter :: dp=8\nreal(dp) :: x').replace('print *,log(x)','x=0.0_dp\nprint *,log(x)'),'',category='runtime',baseline='skip')
add('real64_exp_overflow',prog('print *,exp(x)',decl='integer, parameter :: dp=8\nreal(dp) :: x').replace('print *,exp(x)','x=1000.0_dp\nprint *,exp(x)'),'',category='runtime',baseline='skip')
# Each static rejection has a prelude print: eager compilation must prevent leakage.
def reject(name,source,baseline='reject'):
    add(name,source,category='invalid',baseline=baseline)
reject('private_function_not_imported',mp('real function hidden(x) result(y)\nreal,intent(in)::x\ny=x\nend function hidden','print *,777\nprint *,hidden(1.0)',decl='private'))
reject('private_parameter_not_imported',mp('','print *,777\nprint *,secret',decl='private\ninteger,parameter::secret=8'))
reject('only_unknown_name',mp('','print *,777',uses='use m, only : missing'))
reject('only_excludes_function',mp('real function hidden(x) result(y)\nreal,intent(in)::x\ny=x\nend function hidden','print *,777\nprint *,hidden(1.0)',decl='integer,parameter::dp=8',uses='use m, only : dp'))
reject('only_private_name',mp('real function hidden(x) result(y)\nreal,intent(in)::x\ny=x\nend function hidden','print *,777',decl='private',uses='use m, only : hidden'))
reject('kind_undefined',prog('print *,777\nprint *,1.0_unknown'))
reject('kind_unsupported_real16',prog('print *,777\nprint *,x',decl='real(16) :: x'),baseline='compile')
reject('kind_noninteger_parameter',prog('print *,777\nprint *,x',decl='real, parameter :: dp=8\nreal(dp) :: x'))
reject('real64_actual_real32_dummy',mp('subroutine f(x)\nreal,intent(in)::x\nprint *,x\nend subroutine f','print *,777\ncall f(1.0_dp)',decl='integer,parameter::dp=8'))
reject('real32_actual_real64_dummy',mp('subroutine f(x)\nreal(dp),intent(in)::x\nprint *,x\nend subroutine f','print *,777\ncall f(1.0)',decl='integer,parameter::dp=8'))
reject('call_function_as_subroutine',mp('real function f(x) result(y)\nreal,intent(in)::x\ny=x\nend function f','print *,777\ncall f(1.0)'))
reject('subroutine_used_as_function',mp('subroutine f(x)\nreal,intent(in)::x\nprint *,x\nend subroutine f','print *,777\nprint *,f(1.0)'))
reject('subroutine_wrong_arity',mp('subroutine f(x)\nreal,intent(in)::x\nprint *,x\nend subroutine f','print *,777\ncall f()'))
reject('subroutine_wrong_type',mp('subroutine f(x)\nreal,intent(in)::x\nprint *,x\nend subroutine f','print *,777\ncall f(2)'))
reject('subroutine_write_intent_in',mp('subroutine f(x)\nreal,intent(in)::x\nx=2\nend subroutine f','print *,777\ncall f(2.0)'))
reject('subroutine_intent_out',mp('subroutine f(x)\nreal,intent(out)::x\nx=2\nend subroutine f','print *,777\ncall f(2.0)'),baseline='reject')
add('subroutine_optional_dummy',mp('subroutine f(x)\nreal,intent(in),optional::x\nprint *,1\nend subroutine f','print *,777\ncall f()'),'777 1')
add('subroutine_keyword_actual',mp('subroutine f(x)\nreal,intent(in)::x\nprint *,x\nend subroutine f','print *,777\ncall f(x=2.0)'),expected='777 2.0')
reject('subroutine_recursive_cycle',mp('subroutine f(x)\nreal,intent(in)::x\ncall f(x)\nend subroutine f','print *,777\ncall f(2.0)'))
reject('character_wrong_actual',prog('print *,777\ncall f(2)',internal='subroutine f(s)\ncharacter(len=*),intent(in)::s\nprint *,s\nend subroutine f'))
add('format_external_unit',prog("print *,777\nwrite(*,'(a)') 'x'"),'777 x')
add('format_unsupported_group',prog("print *,777\nprint '(2(i5))',3,4"),'777 3 4')
add('formatted_integer',prog("print '(i5)',3"),'    3',compare_mode='lines')
reject('pure_function_print',mp('pure real function f(x) result(y)\nreal,intent(in)::x\nprint *,x\ny=x\nend function f','print *,777\nprint *,f(1.0)'))
reject('intrinsic_wrong_arity',prog('print *,777\nprint *,exp(1.0,2.0)'))
reject('intrinsic_wrong_type',prog('print *,777\nprint *,sqrt(.true.)'))
reject('max_insufficient_args',prog('print *,777\nprint *,max(1.0)'))
# Runtime result reads still use clean independent call frames.
add('function_return_uninitialized',mp('real function f(x) result(y)\nreal,intent(in)::x\nreturn\nend function f','print *,f(2.0)'),'',category='runtime',baseline='compile',diagnostic='uninitialized')
add('subroutine_uninitialized_local',mp('subroutine f(x)\nreal,intent(in)::x\nreal::y\nprint *,y\nend subroutine f','call f(2.0)'),'',category='runtime',baseline='compile',diagnostic='uninitialized')
reject('accessibility_duplicate_private',mp('','print *,777',decl='private\nprivate'))
reject('accessibility_conflicting_defaults',mp('','print *,777',decl='public\nprivate'))
reject('accessibility_unknown_public',mp('','print *,777',decl='public :: unknown'))
reject('accessibility_duplicate_public_attribute',mp('','print *,777',decl='integer,parameter,public :: x=1\npublic :: x'))
reject('character_default_dummy',prog("print *,777\ncall f('abc')",internal='subroutine f(x)\ncharacter,intent(in)::x\nprint *,x\nend subroutine f'),baseline='compile')
reject('double_exponent_kind_suffix',prog('print *,777\nprint *,1.0d0_dp',decl='integer,parameter::dp=8'))
reject('pure_function_impure_call',mp('pure real function f(x) result(y)\nreal,intent(in)::x\ny=g(x)\nend function f\nreal function g(x) result(y)\nreal,intent(in)::x\ny=x\nend function g','print *,777\nprint *,f(1.0)'))
add('continuation_comments',prog('print *,1.0_dp + & ! continued\n\n! intervening comment\n & 2.0_dp',decl='integer,parameter::dp=8'),'3')
reject('continuation_missing_end','program main\nimplicit none\nprint *,1.0 + &\n! no continuation follows')
# Features supported in 0.17.0; preserve every original source fixture.
SUPPORTED_017 = {'character_default_dummy': '777 a'}
for row in manifest:
    if row['name'] in SUPPORTED_017:
        row.update(category='success', baseline='run', expected_stdout=SUPPORTED_017[row['name']])

(suite/'manifest.json').write_text(json.dumps(dict(version='0.7.0',cases=manifest),indent=2)+'\n')
print(len(manifest),'cases')
