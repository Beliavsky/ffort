elemental function char_plus_int(c1,i) result(c12)
! add a string to an integer
character (len=*),   intent(in) :: c1
integer          ,   intent(in) :: i
character (len=*), parameter :: cdelim_ = "_"
character (len=len(c1)+len(cdelim_)+20) :: c12
c12 = trim(c1) // cdelim_ // trim(str(i))
end function char_plus_int
!
