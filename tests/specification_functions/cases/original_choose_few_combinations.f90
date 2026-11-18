module original_combinations
implicit none
integer,parameter::long_int=8
contains
elemental function factorial_long(n) result(ifact)
integer(kind=long_int), intent(in) :: n
integer(kind=long_int)             :: ifact
integer(kind=long_int)             :: i
ifact = 1
do i=2,n
   ifact = ifact*i
end do
end function factorial_long
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
function few_combinations(n,k) result(imat)
integer, intent(in) :: n,k
integer             :: imat(choose(n,k),k)
integer             :: i1,i2,i3,ncomb
ncomb = 0
imat = 0
if (k == 3) then
   do i1=1,n
      do i2=i1+1,n
         do i3=i2+1,n
            ncomb = ncomb + 1
            imat(ncomb,:) = [i1,i2,i3]
         end do
      end do
   end do
end if
end function few_combinations
end module
program check_original
use original_combinations
implicit none
integer::a(10,3)
a=few_combinations(5,3)
print *,choose(5,3),choose(4,5),choose(0,0),choose(6,1),choose(6,6)
print *,a(:,1)
print *,a(:,2)
print *,a(:,3)
print *,size(few_combinations(2,3)),shape(few_combinations(4,2))
end program
