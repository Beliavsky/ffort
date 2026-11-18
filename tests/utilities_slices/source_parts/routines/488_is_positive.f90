elemental function is_positive(i) result(tf)
integer, intent(in), optional :: i
logical                       :: tf
if (present(i)) then
   tf = i > 0
else
   tf = .false.
end if
end function is_positive
!
