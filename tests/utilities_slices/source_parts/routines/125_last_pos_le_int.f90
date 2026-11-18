pure function last_pos_le_int(ivec,ival) result(ipos)
! return the position of the last element of ivec(:) that is <= ival,
! 0 if none are >=
integer, intent(in) :: ivec(:),ival
integer             :: ipos
integer             :: i,n
n  = size(ivec)
ipos = 0
do i=n,1,-1
   if (ivec(i) <= ival) then
      ipos = i
      exit
   end if
end do
end function last_pos_le_int
!
