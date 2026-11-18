subroutine print_time_elapsed(old_time,fmt_trailer,print_time,title)
! print time elapsed since old_time
real(kind=dp)    , intent(in)           :: old_time ! previously set by call cpu_time(old_time)
character (len=*), intent(in), optional :: fmt_trailer,title
logical          , intent(in), optional :: print_time
real(kind=dp)                           :: new_time
character (len=100)                     :: fmt_time_
! logical                                 :: print_time_
fmt_time_ = "(/,1x,'time elapsed(s)',1x,f0.2,1x,a)"
call cpu_time(new_time)
write (*,fmt_time_) new_time-old_time
if (present(title)) write (*,"(a)") trim(title)
if (present(fmt_trailer)) then
   if (fmt_trailer /= "") then
      if (default(.true.,print_time)) then
         write (*,fmt_trailer,advance="no")
         write (*,"(a)") " at " // now()
      else
         write (*,fmt_trailer)
      end if
   end if
end if
end subroutine print_time_elapsed
!
