function maxloc_match_2(k1,k2,ivec,xx) result(j)
! find the position of the largest value of xx(:) such that ivec(:) == k
integer      , intent(in) :: k1,k2
integer      , intent(in) :: ivec(:,:) ! (n,2)
real(kind=dp), intent(in) :: xx(:)     ! (m)
integer                   :: j
integer                   :: i,n
real(kind=dp)             :: xmax
logical                   :: max_so_far
character (len=*), parameter :: msg = "in maxloc_match, "
n = size(ivec,1)
if (size(xx) /= n) then
   write (*,*) msg,"size(ivec), size(xx) =",size(ivec),size(xx)," must be equal, STOPPING"
   stop
else if (size(ivec,2) /= 2) then
   write (*,*) msg,"size(ivec,2) =",size(ivec,2)," must be 2, STOPPING"
   stop
end if
j = 0
if (n < 1) return
do i=1,n
   if (ivec(i,1) /= k1 .or. ivec(i,2) /= k2) cycle
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
end function maxloc_match_2
!
