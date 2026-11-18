subroutine assert_scalar(tf,msg,stop_error)
! test if tf is true
logical          , intent(in)            :: tf
character (len=*), intent(in)            :: msg
logical          , intent(in) , optional :: stop_error
! integer                                  :: ierr
if (.not. tf) then
   write (*,*) "in " // trim(msg)
   if (present(stop_error)) then
      if (stop_error) then
         write (*,*) "stopping in " // mod_str // "assert_scalar"
         stop
      end if
   end if
end if
! call assert_vec([tf],msg,stop_error,jerr)
end subroutine assert_scalar
!
