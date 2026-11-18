pure function complement(n,ivec) result(jvec)
! return in jvec(:) the integers from 1 to n not found in ivec(:)
integer, intent(in)  :: n
integer, intent(in)  :: ivec(:)
integer, allocatable :: jvec(:)
integer              :: i
logical              :: found(n)
if (n < 1) then
   allocate (jvec(0))
   return
end if
forall (i=1:n) found(i) = any(ivec == i)
call set_alloc(pack([(i,i=1,n)],.not. found),jvec)
end function complement
!
