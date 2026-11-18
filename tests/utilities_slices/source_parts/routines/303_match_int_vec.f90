pure function match_int_vec(ii,ivec) result(ipos)
! return the position of the first element in ivec that
! matches ii, 0 otherwise
integer, intent(in) :: ii(:),ivec(:)
integer             :: ipos(size(ii))
integer             :: i
forall (i=1:size(ii)) ipos(i) = match_int_scalar(ii(i),ivec)
end function match_int_vec
!
