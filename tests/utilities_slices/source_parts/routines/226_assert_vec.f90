subroutine assert_vec(tf,msg,stop_error,jerr)
! test if all elements of tf are true
logical          , intent(in)            :: tf(:)
character (len=*), intent(in)            :: msg
logical          , intent(in) , optional :: stop_error
integer          , intent(out), optional :: jerr
integer                                  :: ierr
ierr = first_false(tf)
if (ierr /= 0) then
   write (*,*) "in " // msg // ", ierr =",ierr
   if (present(stop_error)) then
      if (stop_error) stop
   end if
end if
if (present(jerr)) jerr = ierr
end subroutine assert_vec
!
