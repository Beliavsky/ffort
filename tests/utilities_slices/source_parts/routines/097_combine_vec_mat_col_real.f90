function combine_vec_mat_col_real(x1,x2) result(xmat)
! prepend a vector to the first column of a matrix
real(kind=dp), intent(in) :: x1(:),x2(:,:)
real(kind=dp)             :: xmat(size(x1,1),1+size(x2,2))
call assert_equal("in combine_vec_mat_col_real, size(x1), size(x2,1) =",size(x1),size(x2,1))
xmat = cbind(matrix(x1),x2)
end function combine_vec_mat_col_real
!
