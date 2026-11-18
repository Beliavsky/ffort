pure function unique_ordered_int(ivec) result(jvec)
! return in jvec(:) the unique values of ivec(:), assuming ivec(:) is ordered
integer, intent(in)  :: ivec(:)
integer, allocatable :: jvec(:)
integer              :: n
n = size(ivec)
if (n == 0 .or. n == 1) then
   call set_alloc(ivec,jvec)
   return
end if
call set_alloc(pack(ivec,[.true.,ivec(2:)/=ivec(:n-1)]),jvec)
end function unique_ordered_int
!
