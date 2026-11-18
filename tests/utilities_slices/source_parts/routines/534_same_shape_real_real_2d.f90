pure function same_shape_real_real_2d(x,y) result(tf)
! true if x(:,:) and y(:,:) have the same shape
real(kind=dp), intent(in)           :: x(:,:)
real(kind=dp), intent(in), optional :: y(:,:)
logical                             :: tf
if (present(y)) then
   tf = all(shape(x) == shape(y))
else
   tf = .true.
end if
end function same_shape_real_real_2d
!
