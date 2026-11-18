function all_columns_equal_char(xmat) result(tf)
character (len=*), intent(in) :: xmat(:,:)
logical                       :: tf
integer                       :: i,ncol
ncol = size(xmat,2)
tf = .true.
if (ncol < 2) return
do i=2,ncol
   tf = all(xmat(:,i) == xmat(:,1))
   if (.not. tf) return
end do
end function all_columns_equal_char
!
