function size_optional_real_vec(xx) result(n)
real(kind=dp), intent(in), optional :: xx(:)
integer                             :: n
if (present(xx)) then
   n = size(xx)
else
   n = 0
end if
end function size_optional_real_vec
!
