function piecewise_constant(xx,update) result(yy)
real(kind=dp), intent(in) :: xx(:)        ! (n)
logical      , intent(in) :: update(:)    ! (n)
real(kind=dp)             :: yy(size(xx)) ! (n)
integer                   :: i,n
n = size(xx)
if (n < 1) return
yy(1) = xx(1)
do i=2,n
   if (update(i)) then
      yy(i) = xx(i)
   else
      yy(i) = yy(i-1)
   end if
end do
end function piecewise_constant
!
