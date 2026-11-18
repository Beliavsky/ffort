elemental function str_logical(tf) result(ch)
! convert logical to character
logical,intent(in) :: tf
character(len=5)   :: ch
ch = merge("TRUE ","FALSE",tf)
end function str_logical
!
