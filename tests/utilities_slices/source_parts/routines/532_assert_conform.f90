subroutine assert_conform(x,y,msg)
! assert that two 1D real arrays have the same size
real(kind=dp)    , intent(in)           :: x(:)
real(kind=dp)    , intent(in), optional :: y(:)
character (len=*), intent(in), optional :: msg
if (.not. present(y)) return
if (size(x) /= size(y)) then
   if (present(msg)) write (*,"(a)") trim(msg)
   write (*,*) "in assert_conform, size(x)=",size(x)," size(y)=",size(y)," must be equal, STOPPING"
   stop
end if
end subroutine assert_conform
!
