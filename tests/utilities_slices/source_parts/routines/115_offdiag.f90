pure function offdiag(xx) result(xod)
! extract the off-diagonal of a matrix, in column major order
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp)             :: xod(size(xx,1)*(size(xx,1)-1))
integer                   :: i1,i2,i,n1,n2
n1 = size(xx,1)
n2 = size(xx,2)
do i2=1,n2
   do i1=1,n1
      if (i1 /= i2) then
         i = i + 1
         if (i > size(xod)) return
         xod(i) = xx(i1,i2)
      end if
   end do
end do
end function offdiag
!
