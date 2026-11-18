subroutine append_str(base,new,combined)
! append new(:) to base(:) to create combined(:)
character (len=*), intent(in)               :: base(:),new(:)
character (len=*), intent(out), allocatable :: combined(:)
integer                                     :: nbase,nnew
nbase = size(base)
nnew  = size(new)
allocate (combined(nbase+nnew))
combined(:nbase) = base
combined(nbase+1:) = new
end subroutine append_str
!
