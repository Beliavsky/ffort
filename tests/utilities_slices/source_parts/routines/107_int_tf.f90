elemental function int_tf(tf) result(i)
! convert logical variable to integer
logical, intent(in) :: tf
integer             :: i
if (tf) then
   i = itrue
else
   i = ifalse
end if
end function int_tf
!
