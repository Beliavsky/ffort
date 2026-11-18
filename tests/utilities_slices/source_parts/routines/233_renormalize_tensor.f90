subroutine renormalize_tensor(xx,dim)
! renormalize so that sum(xx,dim=3) = 1.0 everywhere
real(kind=dp), intent(in out) :: xx(:,:,:)
integer      , intent(in)     :: dim
integer                       :: i,j,n1,n2,n3
n1  = size(xx,1)
n2  = size(xx,2)
n3  = size(xx,3)
if (dim == 1) then
   do i=1,n2
      do j=1,n3
         call renormalize(xx(:,i,j))
      end do
   end do
else if (dim == 2) then
   do i=1,n1
      do j=1,n3
         call renormalize(xx(i,:,j))
      end do
   end do
else if (dim == 3) then
   do i=1,n1
      do j=1,n2
         call renormalize(xx(i,j,:))
      end do
   end do
end if
end subroutine renormalize_tensor
!
