pure subroutine remove(ivec,ivalue)
! remove from ivec the elements equal ivalue
integer, intent(in out), allocatable :: ivec(:)
integer, intent(in)                  :: ivalue
if (.not. allocated(ivec)) return
call set_alloc(pack(ivec,ivec/=ivalue),ivec)
end subroutine remove
!
