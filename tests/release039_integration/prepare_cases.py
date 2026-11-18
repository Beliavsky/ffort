#!/usr/bin/env python3
"""Generate clearly synthetic, bounded cross-feature contracts; no upstream copies."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent
CASES=[]
def add(name,body,decl='',category='success',gnu='run',expected='ok\n',diagnostic='',note='',numeric=None):
    source='! Synthetic release039 integration fixture; independently authored.\nprogram main\nuse,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128\nimplicit none\n'+decl+'\n'+body+'\nend program\n'
    path=ROOT/'cases'/(name+'.f90');path.write_text(source)
    row=dict(name=name,source='cases/'+path.name,sha256=hashlib.sha256(source.encode()).hexdigest(),category=category,gnu=gnu,expected=expected,diagnostic=diagnostic,note=note)
    if numeric is not None:row['numeric']=numeric
    CASES.append(row)
def ok(body):return body+"\nwrite(*,'(a)')'ok'"
add('shifted_round_erf',ok('''x=[-1.5_dp,-0.5_dp,0.5_dp,1.5_dp]
y=cshift(anint(x,kind=sp),1_ik)
if(any(y/=[-1._sp,1._sp,2._sp,-2._sp]))error stop 1
if(any(aint(erf(y),kind=dp)/=0._dp))error stop 2
if(kind(y)/=sp.or.kind(aint(erf(y),dp))/=dp)error stop 3'''),'real(dp)::x(4)\nreal(sp)::y(4)')
add('rank2_inverse_round',ok('''x=reshape([-2._dp,0._dp,2._dp,4._dp],[2,2])
y=cshift(aint(asinh(x),kind=sp),1,dim=2)
if(any(y/=reshape([1._sp,2._sp,-1._sp,0._sp],[2,2])))error stop 1
if(any(shape(y)/=[2,2]))error stop 2
if(minexponent(y)/=-125.or.maxexponent(x)/=1024)error stop 3'''),'real(dp)::x(2,2)\nreal(sp)::y(2,2)')
add('rank3_zero_bessel',ok('''x=0._dp
n=1\nn(1,1,1)=0
y=anint(bessel_jn(n,x),kind=sp)
if(y(1,1,1)/=1._sp)error stop 1
t=aint(asinh(erf(y)),kind=dp)
do k=1,2
do j=1,2
do i=1,2
if(i+j+k>3.and.y(i,j,k)/=0._sp)error stop 2
if(t(i,j,k)/=0._dp)error stop 3
end do
end do
end do'''),'real(dp)::x(2,2,2),t(2,2,2)\ninteger::n(2,2,2),i,j,k\nreal(sp)::y(2,2,2)')
add('pointer_shift_composition',ok('''a=[-2.5_dp,-0.5_dp,0.5_dp,2.5_dp]
p=>a(4:1:-1)
q=>a
if(associated(p,q).or..not.associated(q,a))error stop 1
q=cshift(aint(p),1_ik)
if(any(a/=[0._dp,0._dp,-2._dp,2._dp]))error stop 2
if(minexponent(erf(p))/=-1021)error stop 3'''),'real(dp),target::a(4)\nreal(dp),pointer::p(:),q(:)')
add('empty_rank1',ok('''if(size(anint(asinh(erf(x)),sp))/=0)error stop 1
if(size(bessel_jn(33,x))/=0)error stop 2
if(size(cshift(aint(x,dp),1))/=0)error stop 3
if(minexponent(bessel_y0(x))/=-1021)error stop 4'''),'real(dp)::x(0)')
add('empty_rank2',ok('''if(any(shape(aint(acosh(x),sp))/=[2,0]))error stop 1
if(size(bessel_yn(n,x))/=0)error stop 2
if(size(cshift(erf(x),1,dim=1))/=0)error stop 3
if(maxexponent(anint(x,sp))/=128)error stop 4'''),'real(dp)::x(2,0)\ninteger::n(2,0)')
add('metadata_undefined_and_invalid',ok('''if(minexponent(aint(x,sp))/=-125)error stop 1
if(maxexponent(anint(x,dp))/=1024)error stop 2
if(minexponent(bessel_yn(999,acosh(x)))/=-1021)error stop 3
if(maxexponent(erf(1._sp/zero))/=128)error stop 4
if(kind(asinh(1._dp/z))/=dp)error stop 5'''),'real(dp)::x,z\nreal(sp)::zero')
add('metadata_absent_optional',ok('''call check()\ncontains
subroutine check(x)
real(dp),optional,intent(in)::x(:)
if(minexponent(aint(x,sp))/=-125)error stop 1
if(maxexponent(bessel_yn(99,x))/=1024)error stop 2
end subroutine''').replace("\nwrite(*,'(a)')'ok'",''),'',expected='')
add('aliased_parameter_selectors',ok('''if(kind(aint(a,kind=k))/=sp)error stop 1
if(kind(anint(a,dp))/=dp)error stop 2
if(minexponent(aint(a,k))/=-125)error stop 3
if(maxexponent(anint(a,dp))/=1024)error stop 4
if(aint(a,k)/=1._sp.or.anint(a,dp)/=2._dp)error stop 5'''),'integer(ik),parameter::k=sp\nreal(dp),parameter::a=1.75_dp')
add('keyword_composition',ok('''x=0._dp
if(bessel_jn(x=x,n=0_ik)/=1._dp)error stop 1
if(anint(kind=sp,a=bessel_jn(x=x,n=1_ik))/=0._sp)error stop 2
if(aint(kind=dp,a=asinh(x=erf(x=x)))/=0._dp)error stop 3
if(acosh(x=1._dp)/=0._dp)error stop 4'''),'real(dp)::x')
add('erfc_previous_boundary',ok('''x=[0._dp,1._dp,2._dp]
y=cshift(anint(10._dp*erfc_scaled(x),sp),1)
if(any(y/=[4._sp,3._sp,10._sp]))error stop 1
if(minexponent(y)/=-125)error stop 2
if(aint(erf(0._dp))/=0._dp)error stop 3'''),'real(dp)::x(3)\nreal(sp)::y(3)',note='ERFC_SCALED is checked only by the explicit decimal rounding invariants 10,4,3 at x=0,1,2; not an accuracy tolerance.')
add('bessel_quantized_invariants',ok('''x=1._dp
if(anint(1000._dp*bessel_j0(x))/=765._dp)error stop 1
if(anint(1000._dp*bessel_j1(x))/=440._dp)error stop 2
if(anint(1000._dp*bessel_y0(x))/=88._dp)error stop 3
if(anint(1000._dp*bessel_y1(x))/=-781._dp)error stop 4
if(anint(1000._dp*bessel_jn(2_ik,x))/=115._dp)error stop 5
if(anint(1000._dp*bessel_yn(2_ik,x))/=-1651._dp)error stop 6
if(anint(1000._dp*erf(x))/=843._dp)error stop 7'''),'real(dp)::x',note='Only explicit 0.001-wide rounding bins at x=1. Independent math accuracy remains in erf_bessel, with no Bessel amplitude budget imported here.')
add('masked_domains',ok('''x=[0._dp,1._dp,2._dp]
y=-9._dp
where(x>=1._dp)y=aint(acosh(x),sp)
if(any(y/=[-9._dp,0._dp,1._dp]))error stop 1
where(x>0._dp)y=anint(bessel_y0(x),dp)
if(any(y/=[-9._dp,0._dp,1._dp]))error stop 2'''),'real(dp)::x(3),y(3)')
add('strict_scalar_array_shadows',ok('''aint=4._dp
anint=[1._dp,2._dp]
erf=3._dp
bessel_j0=[4._dp,5._dp]
minexponent=6
maxexponent=7
if(aint+erf+anint(2)+bessel_j0(1)/=13._dp)error stop 1
if(minexponent+maxexponent/=13)error stop 2'''),'real(dp)::aint,erf,anint(2),bessel_j0(2)\ninteger::minexponent,maxexponent')
add('strict_procedure_shadow','''if(erf(3._dp)/=13._dp)error stop 1
if(bessel_jn(2,4._dp)/=6._dp)error stop 2
if(minexponent(3._dp)/=23)error stop 3
write(*,'(a)')'ok'
contains
real(dp) function erf(x)
real(dp),intent(in)::x
erf=x+10._dp
end function
real(dp) function bessel_jn(n,x)
integer,intent(in)::n
real(dp),intent(in)::x
bessel_jn=x+n
end function
integer function minexponent(x)
real(dp),intent(in)::x
minexponent=int(x)+20
end function''')
add('exact_numeric_and_zero','''x=[-0._dp,0._dp,-0.25_dp,0.25_dp]
write(*,'(4f6.1)')aint(x)
write(*,'(4f6.1)')anint(x)''','real(dp)::x(4)',expected='',numeric=['-0','0','-0','0','-0','0','-0','0'])
add('exact_integer_metadata','''write(*,'(6i8)')minexponent(0._sp),maxexponent(0._sp), &\nminexponent(0._dp),maxexponent(0._dp),kind(aint(1._dp,sp)),kind(anint(1._sp,dp))''',expected='    -125     128   -1021    1024       4       8\n')
add('round_before_narrowing','''x=1.999999999999_dp
y=0.499999999999_dp
write(*,'(2f6.1)')aint(x,sp),anint(y,sp)''','real(dp)::x,y',gnu='compile',expected='   1.0   0.0\n',note='GNU14 runtime explicit-KIND discrepancy: documented separately at O0/O2, not GNU execution agreement. Argument-first round results are exact1,0.')
add('constant_narrowing','''write(*,'(2f6.1)')aint(1.999999999999_dp,sp),anint(0.499999999999_dp,sp)''',expected='   1.0   0.0\n')
# Checked failures preserve every complete prior record and none of the failing one.
for name,decl,expr,diag in [
('atomic_acosh','real(dp)::x\nx=0._dp','anint(acosh(x),sp)','ACOSH requires X >= 1'),
('atomic_y_singular','real(dp)::x\nx=0._dp','aint(bessel_y0(x),sp)','Bessel Y requires'),
('atomic_order','integer(ik)::n\nn=33_ik','erf(bessel_jn(n,1._dp))','Bessel N outside supported range'),
('atomic_x_bound','real(dp)::x\nx=1048577._dp','asinh(bessel_j0(x))','Bessel X'),
('atomic_narrow_overflow','real(dp)::x\nx=huge(1._dp)','aint(x,sp)','AINT/ANINT result overflows REAL kind 4'),
]:
    # Initialization is executable and belongs after declarations.
    ds,init=decl.split('\n',1)
    add(name,init+"\nwrite(*,'(a)')'before'\nwrite(*,*)'partial',"+expr,ds,category='runtime',gnu='compile',expected='before\n',diagnostic=diag,note='GNU compile-only; executing this diagnostic/domain/resource boundary is deliberately excluded.')
add('runtime_dynamic_shape',"""allocate(x(2))\nallocate(n(3))
x=0._dp
n=0
write(*,'(a)')'before'
write(*,*)'partial',anint(bessel_jn(n,x),sp)""",'real(dp),allocatable::x(:)\ninteger,allocatable::n(:)',category='runtime',gnu='compile',expected='before\n',diagnostic='conform',note='GNU execution excluded for nonconforming dynamic elemental operands.')
for name,decl,expr in [
('reject_round_logical','','aint(.true.)'),
('reject_bessel_real_order','','bessel_jn(2._dp,1._dp)'),
('reject_model_integer','','minexponent(1)'),
('reject_duplicate_kind','','anint(1._dp,sp,kind=dp)'),
('reject_runtime_kind','integer::k\nk=sp','aint(1._dp,k)'),
('reject_noncallable_shadow','real(dp)::erf\nerf=1._dp','erf(0._dp)'),
]:
    ds,*init=decl.split('\n',1)
    add(name,('\n'.join(init)+'\n' if init else '')+'print *,'+expr,ds,category='reject',gnu='reject',expected='',diagnostic={'reject_round_logical':'requires REAL kind 4 or 8','reject_bessel_real_order':'Bessel N requires INTEGER','reject_model_integer':'requires REAL X','reject_duplicate_kind':'Repeated actual argument for kind','reject_runtime_kind':'KIND must be constant','reject_noncallable_shadow':'Cannot subscript a scalar variable'}[name])
add('reject_unsupported_three_arg','','',category='reject',gnu='compile',expected='',diagnostic='ERF/Bessel requires X',note='Legal Fortran transformational BESSEL_JN is deliberately unsupported; GNU compile-only.')
# Ensure the legal unsupported fixture remains a real three-argument call.
p=ROOT/'cases/reject_unsupported_three_arg.f90';s=p.read_text().replace('\n\nend program','\nprint *,bessel_jn(0,2,1._dp)\nend program');p.write_text(s);CASES[-1]['sha256']=hashlib.sha256(s.encode()).hexdigest()
(ROOT/'synthetic-manifest.json').write_text(json.dumps(dict(scope='All cases synthetic; no whole-library execution claim.',cases=CASES),indent=2)+'\n')
print(len(CASES))
