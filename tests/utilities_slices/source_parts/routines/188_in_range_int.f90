elemental function in_range_int(i,imin,imax) result(tf)
! return .true. if i >= imin and i <= imax
! if imin or imin is not present, the condition is satisfied
integer, intent(in)           :: i
integer, intent(in), optional :: imin,imax
logical                       :: tf
tf = .true.
if (present(imin))      then
   tf = i >= imin
   if (.not. tf) return
end if
if (present(imax)) then
   tf = i <= imax
   if (.not. tf) return
end if
end function in_range_int
!
