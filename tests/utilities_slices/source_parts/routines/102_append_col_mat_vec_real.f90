function append_col_mat_vec_real(x1,x2) result(xmat)
real(kind=dp), intent(in) :: x1(:,:),x2(:)
real(kind=dp)             :: xmat(size(x2),size(x1,2)+1)
integer                   :: ncol_x1
ncol_x1 = size(x1,2)
if (size(x1,1) == size(x2)) then
   xmat(:,:ncol_x1)  = x1
   xmat(:,ncol_x1+1) = x2
else
   write (*,*) "shape(x1)=",shape(x1)," shape(x2)=",shape(x2)
   write (*,*) "error in append_col_vec_mat_real, RETURNING"
   return
end if
end function append_col_mat_vec_real
!
