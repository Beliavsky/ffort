elemental function int_within(i,i1,i2) result(tf)
integer, intent(in) :: i,i1,i2
logical             :: tf
tf = i >= i1 .and. i <= i2
end function int_within
!
