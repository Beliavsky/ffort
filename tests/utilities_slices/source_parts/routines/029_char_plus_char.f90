elemental function char_plus_char(c1,c2) result(c12)
! trim two strings and add them
character (len=*),   intent(in) :: c1,c2
character (len=len(c1)+len(c2)) :: c12
c12 = trim(c1) // trim(c2)
end function char_plus_char
!
