elemental function choose(n,k) result(j)
integer, intent(in)    :: n,k
integer                :: j
integer                :: i
integer(kind=long_int) :: numer,k_
if (k > n) then
   j = 0
   return
end if
if (n < 1) then
   j = 1
   return
end if
if (n == k .or. k == 0) then
   j = 1
   return
else if (k == 1 .or. k == n-1) then
   j = n
   return
end if
k_ = merge(n-k,k,k > n/2) 
numer = 1
do i=n-k_+1,n
   numer = numer*i
end do
j = numer/factorial_long(k_)
! print*,n,k,numer,factorial(k),j
end function choose
!
