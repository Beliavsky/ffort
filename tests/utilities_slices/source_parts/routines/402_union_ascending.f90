pure function union_ascending(xx,yy) result(zz)
! return the union of xx(:) and yy(:), assuming they are in ascending order
integer, intent(in)  :: xx(:),yy(:)
integer, allocatable :: zz(:)
integer              :: i,ix,iy,nx,ny,nz
logical              :: use_x
nx = size(xx)
ny = size(yy)
nz = nx + ny
allocate (zz(nz))
if (nx == 0 .or. ny == 0) then
   call set_alloc(unique_ordered([xx,yy]),zz)
   return
end if
ix = 1
iy = 1
do i=1,nz
   if (ix > nx) then
      use_x = .false.
   else if (iy > ny) then
      use_x = .true.
   else
      use_x = xx(ix) < yy(iy)
   end if
   if (use_x) then
      zz(i) = xx(ix)
      ix = ix + 1
   else
      zz(i) = yy(iy)
      iy = iy + 1
   end if
end do
call set_alloc(unique_ordered(zz),zz)
end function union_ascending
!
