subroutine merge_alloc_int(itrue,ifalse,tf,ivec)
integer, intent(in)               :: itrue(:),ifalse(:)
logical, intent(in)               :: tf
integer, intent(out), allocatable :: ivec(:)
if (tf) then
   call set_alloc(itrue,ivec)
else
   call set_alloc(ifalse,ivec)
end if
end subroutine merge_alloc_int
!
