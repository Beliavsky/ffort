function sorted_real(xx) result(tf)
! return .true. if xx(:) is sorted in ascending order
real(kind=dp), intent(in) :: xx(:)
logical                   :: tf
integer                   :: i,n
tf = .true.
n  = size(xx)
do i=1,n-1
   if (xx(i) > xx(i+1)) then
      tf = .false.
      exit
   end if
end do
end function sorted_real
!
