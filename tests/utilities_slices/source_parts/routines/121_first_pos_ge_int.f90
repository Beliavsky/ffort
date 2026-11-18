pure function first_pos_ge_int(ivec,ival) result(ipos)
! return the position of the first element of ivec(:) that is >= ival,
! n+1 if none are >= ival
integer, intent(in) :: ivec(:),ival
integer             :: ipos
integer             :: i,n
n    = size(ivec)
ipos = n+1
do i=1,n
   if (ivec(i) >= ival) then
      ipos = i
      exit
   end if
end do
end function first_pos_ge_int
!
