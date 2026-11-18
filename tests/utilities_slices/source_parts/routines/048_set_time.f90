subroutine set_time(time_cpu,time_clock)
real(kind=dp), intent(out) :: time_cpu
integer      , intent(out) :: time_clock
call cpu_time(time_cpu)
call system_clock(time_clock)
end subRoutine set_time
!
