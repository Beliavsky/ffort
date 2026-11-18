program integration_main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64
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
write(*,'(a)')'ok'
end program
