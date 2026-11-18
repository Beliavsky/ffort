subroutine append_int(base,new,combined)
! for integer arrays, append new(:) to base(:) to create combined(:)
integer, intent(in)               :: base(:),new(:)
integer, intent(out), allocatable :: combined(:)
integer                           :: nbase,nnew
nbase = size(base)
nnew  = size(new)
allocate (combined(nbase+nnew))
combined(:nbase) = base
combined(nbase+1:) = new
end subroutine append_int
!
