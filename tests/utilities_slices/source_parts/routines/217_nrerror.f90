subroutine nrerror(string)
character(len=*), intent(in) :: string
write (*,*) "nrerror: ",string
stop "program terminated by nrerror"
end subroutine nrerror
!
