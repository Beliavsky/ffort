function conform_optional_real_2d(xx,yy) result(tf)
! check that two matrices are conformable if they are present
real(kind=dp), intent(in)           :: xx(:,:)
real(kind=dp), intent(in), optional :: yy(:,:)
logical                             :: tf
if (present(yy)) then
   tf = all(shape(xx) == shape(yy))
else
   tf = .true.
end if
end function conform_optional_real_2d
!
