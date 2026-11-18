function combine_mat_col_real(x1,x2) result(xmat)
! combine matrices by column
real(kind=dp), intent(in) :: x1(:,:),x2(:,:)
real(kind=dp)             :: xmat(size(x1,1),size(x1,2)+size(x2,2))
integer                   :: ncol_1
ncol_1 = size(x1,2)
if (size(x1,1) == size(x2,1)) then
   xmat(:,:ncol_1)   = x1
   xmat(:,ncol_1+1:) = x2
else
   write (*,*) mod_str,"size(x1,1), size(x2,1) =",size(x1,1),size(x2,1)," must be equal, stoppinG"
   stop
end if
end function combine_mat_col_real
!
