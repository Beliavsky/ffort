pure function char_not_in_vec(i,ivec) result(tf)
character (len=*), intent(in) :: i,ivec(:)
logical                       :: tf
tf = .not. (any(i == ivec))
! tf = .not. char_in_vec(i,ivec)
end function char_not_in_vec
!
