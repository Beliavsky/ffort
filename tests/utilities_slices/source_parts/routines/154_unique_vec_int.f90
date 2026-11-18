function unique_vec_int(ivec) result(jvec)
! return in jvec the unique values of ivec(:)
integer, intent(in)  :: ivec(:)
integer, allocatable :: jvec(:)
integer              :: n,nuniq
integer              :: ipos(size(ivec))
n = size(ivec)
! print*,"ivec=",ivec !! debug
call unique_int(ivec,ipos,nuniq)
! print*,"nuniq=",nuniq !! debug
if (nuniq > 0) then
   call set_alloc(ivec(ipos(:nuniq)),jvec)
else
   allocate (jvec(0))
end if
end function unique_vec_int
!
