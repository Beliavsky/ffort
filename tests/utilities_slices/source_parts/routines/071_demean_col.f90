function demean_col(xx,cdemean) result(xdm)
! demean each column of xx(:,:) by default(1,cdemean) of column mean
real(kind=dp), intent(in)           :: xx(:,:)
real(kind=dp), intent(in), optional :: cdemean
real(kind=dp)                       :: xdm(size(xx,1),size(xx,2))
xdm = demean_mat(xx,cdemean)
end function demean_col
!
