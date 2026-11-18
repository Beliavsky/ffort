function combine_mat_vec_col_real(x1,x2) result(xmat)
! append a vector to the first column of a matrix
real(kind=dp), intent(in) :: x1(:,:),x2(:)
real(kind=dp)             :: xmat(size(x1,1),1+size(x1,2))
call assert_equal("in combine_mat_vec_col_real, size(x1,1), size(x2) =",size(x1,1),size(x2))
! print*,"shape(x1)=",shape(x1)," shape(x2)=",shape(x2) !! debug
xmat = cbind(x1,matrix(x2))
end function combine_mat_vec_col_real
!
