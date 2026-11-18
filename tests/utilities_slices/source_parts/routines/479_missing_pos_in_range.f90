subroutine missing_pos_in_range(ivec,jvec,imin,imax,ipos_miss)
! return the positions in ivec(:) that are not found in jvec(:) and are in the range (imin,imax) inclusive
integer, intent(in)               :: ivec(:),jvec(:),imin,imax
integer, intent(out), allocatable :: ipos_miss(:)    ! positions in ivec(:) not found in jvec(:)
logical                           :: ivec_miss(size(ivec))
integer                           :: i
forall (i=1:size(ivec)) ivec_miss(i) = ivec(i) >= imin .and. ivec(i) <= imax .and. all(ivec(i) /= jvec)
call set_alloc(true_pos(ivec_miss),ipos_miss)
end subroutine missing_pos_in_range
!
