function num_changes_int(ivec) result(nch)
integer, intent(in) :: ivec(:)
integer             :: nch
integer             :: n
n = size(ivec)
if (n > 1) then
   nch = count(ivec(2:) /= ivec(:n-1))
else
   nch = 0
end if
end function num_changes_int
!
