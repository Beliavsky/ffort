function append_col_vec_mat_real(x1,x2) result(xmat)
real(kind=dp), intent(in) :: x1(:),x2(:,:)
real(kind=dp)             :: xmat(size(x1),size(x2,2)+1)
if (size(x1) == size(x2,1)) then
   xmat(:,1)  = x1
   xmat(:,2:) = x2
else
   write (*,*) "error in append_col"
   return
end if
end function append_col_vec_mat_real
!
