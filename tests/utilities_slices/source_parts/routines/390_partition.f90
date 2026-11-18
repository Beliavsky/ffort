pure function partition(n,npart) result(ipart)
integer, intent(in) :: n,npart
integer             :: ipart(npart)
integer             :: i
if (npart <= 0) return
if (n <= 1) then
   ipart = n
   return
end if
if (npart < n) then
   forall (i=1:npart) ipart(i) = nint(n*i/(npart+1.0_dp))
else
   forall (i=1:npart) ipart(i) = i
end if
end function partition
!
