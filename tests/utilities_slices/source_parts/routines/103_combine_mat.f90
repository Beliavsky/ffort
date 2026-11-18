function combine_mat(x1,x2) result(xmat)
real(kind=dp), intent(in) :: x1(:,:),x2(:,:)
real(kind=dp)             :: xmat(size(x1,1),size(x1,2),2)
if (size(x1,1) == size(x2,1) .and. size(x1,2) == size(x2,2)) then
   xmat(:,:,1) = x1
   xmat(:,:,2) = x2
else
   write (*,*) "error in combine_mat"
   return
end if
end function combine_mat
!
