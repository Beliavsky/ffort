function exclude_vec_int(ivec,iexcl) result(jvec)
! return in jvec the elements in ivec except those in position iexcl(:)
integer, intent(in)            :: ivec(:)
integer, intent(in), optional  :: iexcl(:)
integer, allocatable :: jvec(:)
integer              :: i,n,nuse,iuse(size(ivec))
n  = size(ivec)
if (present(iexcl)) then
   nuse = 0
   do i=1,n
      if (all(iexcl /= i)) then
         nuse = nuse + 1
         iuse(nuse) = i
      end if
   end do
   call copy_alloc_vec_int(ivec(iuse(:nuse)),jvec)
else
   allocate (jvec(n))
   jvec = ivec
end if
end function exclude_vec_int
!
