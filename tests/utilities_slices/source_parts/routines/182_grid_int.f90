function grid_int(n,imin,inc) result(ivec)
! return a grid of n values, starting at imin,
! with increments of inc
integer      , intent(in) :: n
integer      , intent(in) :: imin,inc
integer                   :: ivec(n)
integer                   :: i
if (n < 1) return
ivec(1) = imin
do i=2,n
   ivec(i) = ivec(i-1) + inc
end do
end function grid_int
!
