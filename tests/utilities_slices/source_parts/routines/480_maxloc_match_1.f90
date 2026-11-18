function maxloc_match_1(k,ivec,xx) result(j)
! find the position of the largest value of xx(:) such that ivec(:) == k
integer      , intent(in) :: k
integer      , intent(in) :: ivec(:) ! (n)
real(kind=dp), intent(in) :: xx(:)   ! (m)
integer                   :: j
integer                   :: i,n
real(kind=dp)             :: xmax
logical                   :: max_so_far
n = size(ivec)
if (size(xx) /= n) then
   write (*,*) "in maxloc_match, size(ivec), size(xx) =",size(ivec),size(xx)," must be equal, STOPPING"
   stop
end if
j = 0
if (n < 1) return
do i=1,n
   if (ivec(i) /= k) cycle
   max_so_far = .false.
   if (i == 1) then
      max_so_far = .true.
      j = 1
      xmax = xx(i)
   else if (xx(i) > xmax) then
      max_so_far = .true.
   end if
   if (max_so_far) then
      j    = i
      xmax = xx(i)
   end if
end do
end function maxloc_match_1
!
