function time_elapsed(old_time) result(ytime)
real(kind=dp)    , intent(in) :: old_time
real(kind=dp)                 :: ytime
real(kind=dp)                 :: new_time
call cpu_time(new_time)
ytime = new_time - old_time
end function time_elapsed
!
