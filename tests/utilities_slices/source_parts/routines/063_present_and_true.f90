pure function present_and_true(xx) result(tf)
logical, intent(in), optional :: xx
logical                       :: tf
if (present(xx)) then
   tf = xx
else
   tf = .false.
end if
end function present_and_true
!
