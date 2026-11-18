pure function match_string_vec(ii,ivec) result(ipos)
! return the position of the first element in ivec that
! matches ii, 0 otherwise
character (len=*), intent(in) :: ii(:),ivec(:)
integer                       :: ipos(size(ii))
integer                       :: i
forall (i=1:size(ii)) ipos(i) = match_string_scalar(ii(i),ivec)
end function match_string_vec
!
