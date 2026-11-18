function wall_time_elapsed(old_time) result(xtime)
! return the wall clock time elapsed in seconds
integer          , intent(in)           :: old_time ! set with call system_clock(old_time)
real(kind=dp)                           :: xtime
integer                                 :: itick,new_time
call system_clock(new_time,itick)
xtime = (new_time-old_time)/dble(itick)
end function wall_time_elapsed
!
