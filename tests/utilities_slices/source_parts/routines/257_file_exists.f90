function file_exists(xfile) result(tf)
! return .true. if a file xfile exists, otherwise .false.
character (len=*), intent(in) :: xfile
logical                       :: tf
inquire (file=xfile,exist=tf)
! print*,trim(xfile)," ",tf !! debug
end function file_exists
!
