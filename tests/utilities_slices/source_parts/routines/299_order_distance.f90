function order_distance(xx,xvec) result(nd)
real(kind=dp), intent(in) :: xx,xvec(:)
integer                   :: nd
integer                   :: i,n
n = size(xvec)
nd = 0
do i=1,n
   if (xvec(i) == xx) then
      continue
   else if (xvec(i) > xx) then
      nd = nd + 1
   else
      nd = nd - 1
   end if
end do
end function order_distance
!
