function vec_exclude_int(ivec,values_exclude) result(jvec)
! return in jvec(:) the values of ivec(:) not in values_exclude(:)
integer, intent(in)  :: ivec(:)
integer, intent(in)  :: values_exclude(:)
integer, allocatable :: jvec(:)
integer              :: i,kvec(size(ivec)),nk
nk = 0
do i=1,size(ivec)
   if (ivec(i) .notin. values_exclude) then
      nk = nk + 1
      kvec(nk) = ivec(i)
   end if
end do
allocate (jvec(nk))
jvec = kvec(:nk)
end function vec_exclude_int
!
