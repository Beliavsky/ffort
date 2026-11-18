subroutine match_char(xgood,xx,iuse)
! return in iuse(:) the positions in xx(:) of elements that are found in xgood(:)
character (len=*), intent(in)               :: xgood(:)
character (len=*), intent(in)               :: xx(:)
integer          , intent(out), allocatable :: iuse(:)
logical                                     :: xmask(size(xx))
integer                                     :: i,j,n,nuse
n = size(xx)
forall (i=1:n) xmask(i) = any(xgood == xx(i))
nuse = count(xmask)
allocate (iuse(nuse))
j = 0
do i=1,n
   if (xmask(i)) then
      j = j + 1
      iuse(j) = i
      if (j == nuse) exit
   end if
end do
end subroutine match_char
!
