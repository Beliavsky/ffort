#!/usr/bin/env python3
"""Generate only synthetic integration fixtures and independent mathematical oracles."""
from pathlib import Path
import hashlib,json,math,struct
import mpmath as mp
ROOT=Path(__file__).resolve().parent
mp.mp.dps=120
cases=[]
def add(name,body,expected='ok\n',category='success',gnu='run',diagnostic='',note='',numeric=None,gnu_expected=None):
    src='program integration_main\n'+body.strip()+'\nend program\n'
    rel='cases/'+name+'.f90';(ROOT/rel).write_text(src)
    c=dict(name=name,source=rel,sha256=hashlib.sha256(src.encode()).hexdigest(),category=category,gnu=gnu,expected=expected,diagnostic=diagnostic,note=note)
    if numeric is not None:c['numeric']=numeric
    if gnu_expected is not None:c['gnu_expected']=gnu_expected
    cases.append(c)
def f32(x):return struct.unpack('f',struct.pack('f',x))[0]
def ref(x,kind):
    x=f32(x) if kind==4 else float(x);z=mp.mpf(x)
    if z>mp.mpf('1e8'):
        # Asymptotic alternating expansion. At these positive inputs the next
        # omitted term bounds the error, far below one binary32/binary64 ULP.
        v=(1-1/(2*z*z)+3/(4*z**4))/(mp.sqrt(mp.pi)*z)
    else:v=mp.exp(z*z)*mp.erfc(z)
    rounded=f32(float(v)) if kind==4 else float(v)
    step=mp.mpf(2)**(max(-149,math.frexp(rounded)[1]-24) if kind==4 else max(-1074,math.frexp(rounded)[1]-53))
    return dict(input_hex=x.hex(),kind=kind,value=mp.nstr(v,115),ulp=mp.nstr(step,115),max_ulp=2 if kind==4 else 4)
add('aliased_erfc_shift', '''use,intrinsic::iso_fortran_env,only:dp=>real64,wide=>int64
implicit none
real(dp)::a(2,3),b(2,3)
integer(wide)::s(2)
a=reshape([0._dp,0.5_dp,1._dp,2._dp,3._dp,4._dp],[2,3])
s=[1_wide,-1_wide]
b=cshift(dim=2_wide,shift=s,array=erfc_scaled(x=a))
write(*,*)b''',expected='',numeric=[ref(x,8) for x in [1,4,3,.5,0,2]])
add('pointer_order_and_shift', '''use,intrinsic::iso_fortran_env,only:ik=>int64
implicit none
integer(ik),target::a(6)
integer(ik),pointer::p(:),q(:)
integer(ik)::b(3)
p=>a(1:5:2)
q=>a(5:1:-2)
if(.not.associated(target=a(1:5:2),pointer=p))error stop 1
if(associated(p,q))error stop 2
if(associated(p,a(2:6:2)))error stop 3
a=[1_ik,2_ik,3_ik,4_ik,5_ik,6_ik]
b=cshift(p,1_ik)
if(any(b/=[3_ik,5_ik,1_ik]))error stop 4
if(.not.associated(p,a(1:5:2)))error stop 5
write(*,'(a)')'ok' ''')
add('shift_snapshot_alias', '''use,intrinsic::iso_fortran_env,only:i8=>int64
implicit none
integer(i8),target::a(3,2)
integer(i8),pointer::p(:)
a=reshape([1_i8,2_i8,3_i8,4_i8,5_i8,6_i8],[3,2])
p=>a(:,1)
a=cshift(a,shift=a(1,:),dim=1)
if(any(a/=reshape([2_i8,3_i8,1_i8,5_i8,6_i8,4_i8],[3,2])))error stop 1
if(.not.associated(p,a(:,1)))error stop 2
write(*,'(a)')'ok' ''')
add('shift_int64_extremes', '''use,intrinsic::iso_fortran_env,only:ik=>int64
implicit none
integer(ik)::big,small
integer::a(5),b(5)
big=huge(0_ik)
small=-big-1_ik
a=[1,2,3,4,5]
b=cshift(a,big)
if(any(b/=[3,4,5,1,2]))error stop 1
b=cshift(a,small)
if(any(b/=[3,4,5,1,2]))error stop 2
b=cshift(cshift(a,big),small)
if(any(b/=[5,1,2,3,4]))error stop 3
write(*,'(a)')'ok' ''')
add('cshift_exact_tiny_values', """use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64
implicit none
real(sp)::a(4),b(4),s
real(dp)::c(4),d(4),t
s=tiny(1._sp)*epsilon(1._sp)
t=tiny(1._dp)*epsilon(1._dp)
a=[s,-s,tiny(1._sp),-tiny(1._sp)]
c=[t,-t,tiny(1._dp),-tiny(1._dp)]
b=cshift(a,1)
d=cshift(c,-1)
if(s==0._sp.or.t==0._dp)error stop 1
if(any(b/=[-s,tiny(1._sp),-tiny(1._sp),s]))error stop 2
if(any(d/=[-tiny(1._dp),t,-t,tiny(1._dp)]))error stop 3
if(any(b==0._sp).or.any(d==0._dp))error stop 4
write(*,'(a)')'ok' """)
add('character_logical_matrix', '''use,intrinsic::iso_fortran_env,only:ik=>int64
implicit none
character(3)::a(2,3),b(2,3)
logical::m(2,3),n(2,3)
a=reshape(['a  ',' bb','ccc','dd ',' e ','fff'],[2,3])
b=cshift(dim=2,shift=[1_ik,-1_ik],array=a)
if(any(b/=reshape(['ccc','fff',' e ',' bb','a  ','dd '],[2,3])))error stop 1
m=reshape([.true.,.false.,.false.,.true.,.true.,.false.],[2,3])
n=cshift(m,shift=[1,-1],dim=2)
if(any(n.neqv.reshape([.false.,.false.,.true.,.false.,.true.,.true.],[2,3])))error stop 2
write(*,'(6(a3,"|"))')b''',expected='ccc|fff| e | bb|a  |dd |\n')
add('empty_rank_two', '''use,intrinsic::iso_fortran_env,only:dp=>real64,i8=>int64
implicit none
real(dp)::a(0,3),b(0,3),c(2,0),d(2,0)
integer(i8)::s(3)
s=[huge(0_i8),-huge(0_i8),0_i8]
b=cshift(erfc_scaled(a),s,dim=1)
d=erfc_scaled(cshift(c,[1_i8,-1_i8],dim=2))
if(size(b)/=0.or.size(b,1)/=0.or.size(b,2)/=3)error stop 1
if(size(d)/=0.or.size(d,1)/=2.or.size(d,2)/=0)error stop 2
write(*,'(a)')'ok' ''',gnu='compile',note='GNU14 runtime -fcheck rejects valid zero-axis CSHIFT with vector SHIFT. Exact shape/value candidate assertions retained; standalone GNU evidence saved.')
add('metadata_inquiries', '''use,intrinsic::iso_fortran_env,only:dp=>real64,ik=>int64
implicit none
real(dp),target::a(3)
real(dp)::x
real(dp),pointer::p(:)
integer(ik)::s,d
if(kind(cshift(erfc_scaled(a),s,d))/=dp)error stop 1
if(kind(associated(p,a))/=4)error stop 2
x=-huge(1._dp)
if(kind(erfc_scaled(x))/=dp)error stop 3
write(*,'(a)')'ok' ''',gnu='compile',note='KIND metadata inquiries do not evaluate undefined values or overflowing ERFC_SCALED argument.')
add('empty_pointer_identity', '''use,intrinsic::iso_fortran_env,only:dp=>real64
implicit none
real(dp),target::a(0),b(0)
real(dp),pointer::p(:),q(:)
p=>a
q=>b
if(.not.associated(p))error stop 1
if(associated(p,a).or.associated(p,p).or.associated(p,q))error stop 2
if(size(cshift(erfc_scaled(a),1))/=0)error stop 3
write(*,'(a)')'ok' ''')
add('source_shadowing', '''use,intrinsic::iso_fortran_env,only:dp=>real64
implicit none
integer::real64
real(dp)::a(3)
real64=3
a=cshift([1._dp,2._dp,3._dp],real64)
if(any(a/=[4._dp,5._dp,6._dp]))error stop 1
if(erfc_scaled(2._dp)/=12._dp)error stop 2
write(*,'(a)')'ok'
contains
function cshift(a,n) result(r)
real(dp),intent(in)::a(:)
integer,intent(in)::n
real(dp)::r(size(a))
r=a+n
end function
function erfc_scaled(x) result(r)
real(dp),intent(in)::x
real(dp)::r
r=x+10._dp
end function''')
add('absent_optional_target', '''implicit none
integer,target::a(3)
integer,pointer::p(:)
p=>a
call probe(p)
write(*,'(a)')'ok'
contains
subroutine probe(p,t)
integer,pointer,intent(in)::p(:)
integer,target,optional,intent(in)::t(:)
if(.not.associated(p,t))error stop 1
end subroutine''',gnu='compile',note='Spec-only: absent whole nonpointer OPTIONAL TARGET means omitted optional intrinsic argument (F2018 15.5.2.12p4,16.2.1p2,16.9.16p5). GNU14 false/crash discrepancy excludes execution.')
add('real128_sentinel', '''use,intrinsic::iso_fortran_env,only:q=>real128,dp=>real64
implicit none
write(*,'(i0,1x,i0)')q,kind(erfc_scaled(1._dp))''',expected='-1 8\n',gnu_expected='16 8\n',note='Processor-specific supported kind sentinel; GNU14 REAL128=16, candidate=-1. Not differential output agreement.')
add('erfc_extreme_composition', '''use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64
implicit none
real(sp)::a(2),b(2)
real(dp)::c(2),d(2)
a=[huge(1._sp),-9.3824138641357421875_sp]
c=[huge(1._dp),-26.628735713751489_dp]
b=cshift(erfc_scaled(a),1)
d=cshift(erfc_scaled(c),1)
write(*,*)b
write(*,*)d''',expected='',gnu='compile',numeric=[ref(-9.3824138641357421875,4),ref(float.fromhex('0x1.fffffep+127'),4),ref(-26.628735713751489,8),ref(float.fromhex('0x1.fffffffffffffp+1023'),8)],note='Independent 120-digit oracle; 2ULP REAL4 /4ULP REAL8, never relative relaxed comparison. GNU14 prematurely overflows/underflows these endpoints; compile only.')
add('erfc_real4_moderate', '''use,intrinsic::iso_fortran_env,only:sp=>real32
implicit none
real(sp)::a(4),b(4)
a=[-1._sp,0._sp,0.5_sp,2._sp]
b=erfc_scaled(cshift(a,1))
write(*,*)b''',expected='',numeric=[ref(x,4) for x in [0,.5,2,-1]])
add('runtime_erfc_overflow', '''use,intrinsic::iso_fortran_env,only:dp=>real64
implicit none
real(dp)::a(2)
a=[0._dp,-27._dp]
write(*,'(a)')'before'
write(*,*)cshift(erfc_scaled(a),1)''',expected='before\n',category='runtime',gnu='compile',diagnostic='finite result range',note='Overflowing argument is candidate safety-policy probe, GNU compile only.')
add('runtime_undefined_target_pointer', '''implicit none
integer,target::a(3)
integer,pointer::p(:),q(:)
nullify(p)
write(*,'(a)')'before'
write(*,'(l1)')associated(p,q)''',expected='before\n',category='runtime',gnu='compile',diagnostic='association',note='Undefined association status is invalid even when first pointer is disassociated; no GNU execution.')
add('runtime_expired_pointer', """use,intrinsic::iso_fortran_env,only:ik=>int64
implicit none
integer(ik),target::a(2)
integer(ik),pointer::p(:)
write(*,'(a)')'before'
call escape(p)
write(*,'(l1)')associated(p,a)
contains
subroutine escape(p)
integer(ik),pointer,intent(out)::p(:)
integer(ik),target::local(2)
p=>local
end subroutine""",expected='before\n',category='runtime',gnu='compile',diagnostic='lifetime',note='Escaping pointer is rejected at owner-scope return before the later ASSOCIATED inquiry; GNU must not execute expired pointer use.')
add('runtime_empty_shift_undefined', '''use,intrinsic::iso_fortran_env,only:dp=>real64
implicit none
real(dp)::a(0)
integer::s
write(*,'(a)')'before'
write(*,'(i0)')size(cshift(erfc_scaled(a),s))''',expected='before\n',category='runtime',gnu='compile',diagnostic='uninitialized',note='CSHIFT evaluates SHIFT once even when ARRAY is empty.')
add('reject_real128_execution', '''use,intrinsic::iso_fortran_env,only:q=>real128
implicit none
real(q)::x
x=1
print *,x''',expected='',category='reject',gnu='compile',diagnostic='kind',note='REAL128 imports as unsupported sentinel; no REAL16 execution support.')
add('reject_rank_three_shift', '''implicit none
real::a(2,2,2),b(2,2,2)
a=0
b=cshift(erfc_scaled(a),1)''',expected='',category='reject',gnu='compile',diagnostic='rank',note='ERFC_SCALED rank3 is supported, CSHIFT rank3 remains outside bounded subset.')
add('reject_associated_expression', '''implicit none
integer,target::a(3)
integer,pointer::p(:)
p=>a
print *,associated(p,cshift(a,1))''',expected='',category='reject',gnu='reject',diagnostic='target')
add('reject_duplicate_keyword', '''implicit none
real::a(3)
a=0
print *,cshift(array=erfc_scaled(a),shift=1,shift=2)''',expected='',category='reject',gnu='reject',diagnostic='Repeated actual argument')
add('reject_alias_remote_identity', '''use,intrinsic::iso_fortran_env,only:dp=>real64,dp=>int64
implicit none
real(dp)::a(2)
a=0
print *,erfc_scaled(cshift(a,1))''',expected='',category='reject',gnu='compile',diagnostic='import',note='Two distinct remote entities cannot occupy one alias; GNU14 accepts the same-valued conflicting import, so compile only.')
(ROOT/'synthetic-manifest.json').write_text(json.dumps(dict(cases=cases,oracle='Independent exact integer/mapping/shape identities and mpmath1.3.0 at120 decimal digits; exact binary input conversion. No candidate/GNU-derived expected values.'),indent=2)+'\n')
print(len(cases),'synthetic cases')
