function conform_optional_real_1d(xx,yy) result(tf)
! check that two vectors are conformable if they are present
real(kind=dp), intent(in)           :: xx(:)
real(kind=dp), intent(in), optional :: yy(:)
logical                             :: tf
if (present(yy)) then
   tf = size(xx) == size(yy)
else
   tf = .true.
end if
end function conform_optional_real_1d
!
