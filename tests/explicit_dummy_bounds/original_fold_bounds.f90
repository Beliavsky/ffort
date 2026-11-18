module original_utilities
implicit none
contains
subroutine fold_bounds(n,nfolds,i1,i2)
! return i1(:) and i2(:) that specify folds of n
integer, intent(in)  :: n,nfolds
integer, intent(out) :: i1(nfolds),i2(nfolds)
integer              :: j,nelem(nfolds)
if (nfolds < 1 .or. n < 1) then
   i1 = 0
   i2 = 0
   return
end if
nelem = group_sizes(n,nfolds)
i1(1) = 1
i2(1) = 1 + nelem(1) - 1
do j=2,nfolds
   i1(j) = i2(j-1) + 1
   i2(j) = i1(j)   + nelem(j) - 1
end do
end subroutine fold_bounds
recursive pure function group_sizes(n,ngroups) result(nelem)
! return group sizes that add up to n and have the lowest variation possible
integer, intent(in) :: n        ! sum of group sizes
integer, intent(in) :: ngroups  ! # of groups
integer             :: nelem(ngroups)
integer             :: ndiv
if (ngroups < 1) then
   return
else if (ngroups == 1) then
   nelem = max(0,n)
   return
else if (ngroups > n) then
   nelem(1:n) = 1
   nelem(n+1:) = 0
   return
end if
ndiv = n/ngroups
nelem = ndiv + group_sizes(n-ndiv*ngroups,ngroups)
end function group_sizes
end module
program main
use original_utilities
implicit none
integer::lo(5),hi(5)
lo=90
hi=80
call fold_bounds(10,3,lo,hi)
print *,lo,hi
call fold_bounds(2,5,lo,hi)
print *,lo,hi
call fold_bounds(0,3,lo,hi)
print *,lo,hi
call fold_bounds(10,0,lo,hi)
print *,lo,hi
end program
