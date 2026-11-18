pure function sum_ranges(xx,ilast,default_sum) result(xsums)
real(kind=dp), intent(in)           :: xx(:)
integer      , intent(in)           :: ilast(:)
real(kind=dp), intent(in), optional :: default_sum
real(kind=dp)                       :: xsums(size(ilast))
integer                             :: i,j1,j2,n
n = size(xx)
xsums = default(0.0_dp,default_sum)
do i=1,size(ilast)
   if (i == 1) then
      j1 = 1
   else
      j1 = ilast(i-1) + 1
   end if
   j2 = ilast(i)
   if (j1 <= n .and. j1 > 0 .and. j2 <= n .and. j2 > 0) xsums(i) = sum(xx(j1:j2))
end do
end function sum_ranges
!
