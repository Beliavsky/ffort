pure function char_vec_in_vec(jvec,ivec) result(tf)
! return .true. for each element of jvec(:) found in ivec(:)
character (len=*), intent(in) :: jvec(:),ivec(:)
logical                       :: tf(size(jvec))
integer                       :: i
forall (i=1:size(jvec)) tf(i) = any(jvec(i) == ivec)
end function char_vec_in_vec
!
