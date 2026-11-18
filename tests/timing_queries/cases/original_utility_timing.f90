module timing_originals
implicit none
integer,parameter::dp=kind(0d0)
integer::old_time_
contains
subroutine init_wall_time()
call system_clock(old_time_)
end subroutine init_wall_time

subroutine set_time(time_cpu,time_clock)
real(kind=dp), intent(out) :: time_cpu
integer      , intent(out) :: time_clock
call cpu_time(time_cpu)
call system_clock(time_clock)
end subRoutine set_time

function wall_time_elapsed(old_time) result(xtime)
! return the wall clock time elapsed in seconds
integer          , intent(in)           :: old_time ! set with call system_clock(old_time)
real(kind=dp)                           :: xtime
integer                                 :: itick,new_time
call system_clock(new_time,itick)
xtime = (new_time-old_time)/dble(itick)
end function wall_time_elapsed

function time_elapsed(old_time) result(ytime)
real(kind=dp)    , intent(in) :: old_time
real(kind=dp)                 :: ytime
real(kind=dp)                 :: new_time
call cpu_time(new_time)
ytime = new_time - old_time
end function time_elapsed

end module
program test
use timing_originals
implicit none
integer::c
real(dp)::t,a,b
call init_wall_time()
call set_time(t,c)
a=wall_time_elapsed(c)
b=time_elapsed(t)
if(a/=a.or.b/=b)stop 1
print *,"PASS"
end program
