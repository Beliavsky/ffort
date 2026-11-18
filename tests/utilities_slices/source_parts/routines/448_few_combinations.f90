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
!
