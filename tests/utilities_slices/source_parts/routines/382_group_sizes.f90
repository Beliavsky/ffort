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
!
