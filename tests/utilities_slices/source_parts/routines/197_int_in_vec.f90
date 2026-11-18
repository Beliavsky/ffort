pure function int_in_vec(i,ivec) result(tf)
integer, intent(in) :: i,ivec(:)
logical             :: tf
tf = (any(i == ivec))
end function int_in_vec
!
