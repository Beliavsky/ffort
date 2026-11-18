subroutine print_wall_time_elapsed(old_time,fmt_trailer,outu,t1_cpu)
! print the time elapsed since old_time by calling system_clock
integer          , intent(in), optional :: old_time ! initialized with call system_clock(old_time)
character (len=*), intent(in), optional :: fmt_trailer
integer          , intent(in), optional :: outu
real(kind=dp)    , intent(in), optional :: t1_cpu
integer                                 :: itick,new_time,outu_
real(kind=dp)                           :: new_time_cpu
character (len=100)                     :: fmt_time_
if (present(old_time)) old_time_ = old_time
outu_ = default(istdout,outu)
fmt_time_ = "(/,1x,'wall time elapsed(s) = ',f9.3)"
call system_clock(new_time,itick)
write (outu_,fmt_time_) (new_time-old_time_)/dble(itick)
if (present(t1_cpu)) then
   call cpu_time(new_time_cpu)
   write (outu_,"(1x,' cpu time elapsed(s) = ',f9.3)") new_time_cpu-t1_cpu
end if
if (present(fmt_trailer)) then
   if (fmt_trailer /= "") write (outu_,fmt_trailer)
end if
end subroutine print_wall_time_elapsed
!
