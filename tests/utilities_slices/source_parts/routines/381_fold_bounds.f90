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
!
