function rebase_mat(xx,method,base) result(yy)
real(kind=dp)    , intent(in) :: xx(:,:)
character (len=*), intent(in) :: method
real(kind=dp)    , intent(in), optional :: base
real(kind=dp)                           :: yy(size(xx,1),size(xx,2))
integer                                 :: icol
do icol=1,size(xx,2)
   yy(:,icol) = rebase_vec(xx(:,icol),method,base)
end do
end function rebase_mat
!
