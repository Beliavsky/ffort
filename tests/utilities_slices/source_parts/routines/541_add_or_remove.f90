pure subroutine add_or_remove(ivec,ivalue)
! If one or more elements of ivec equal ivalue, remove them. If no element of ivec equals ivalue, add it to the end.
integer, intent(in out), allocatable :: ivec(:)
integer, intent(in)                  :: ivalue
if (.not. allocated(ivec)) then
   call set_alloc([ivalue],ivec)
   return
end if
if (any(ivec == ivalue)) then
   call set_alloc(pack(ivec,ivec/=ivalue),ivec)
else
   call set_alloc([ivec,ivalue],ivec)
end if
end subroutine add_or_remove
!
