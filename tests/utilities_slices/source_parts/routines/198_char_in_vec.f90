pure function char_in_vec(i,ivec) result(tf)
! return .true. if any element of ivec(:) equals i
character (len=*), intent(in) :: i,ivec(:)
logical                       :: tf
tf = (any(i == ivec))
end function char_in_vec
!
