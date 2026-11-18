subroutine missing_pos(ivec,jvec,ipos_miss)
! return the positions in ivec(:) that are not found in jvec(:)
integer, intent(in)               :: ivec(:),jvec(:)
integer, intent(out), allocatable :: ipos_miss(:)    ! positions in ivec(:) not found in jvec(:)
logical                           :: ivec_miss(size(ivec))
integer                           :: i
forall (i=1:size(ivec)) ivec_miss(i) = all(jvec /= ivec(i))
call set_alloc(true_pos(ivec_miss),ipos_miss)
end subroutine missing_pos
!
