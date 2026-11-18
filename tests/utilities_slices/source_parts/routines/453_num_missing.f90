function num_missing(ivec,jvec) result(nmiss)
! return the number of elements of jvec not found in ivec
integer, intent(in) :: ivec(:),jvec(:)
integer             :: nmiss
integer             :: i
nmiss = 0
do i=1,size(jvec)
   if (all(jvec(i) /= ivec)) nmiss = nmiss + 1
end do
end function num_missing
!
