pure function int_not_in_vec(i,ivec) result(tf)
integer, intent(in) :: i,ivec(:)
logical             :: tf
tf = .not. int_in_vec(i,ivec)
end function int_not_in_vec
!
