pure function last_pos_le_int_vec(ivec,ival) result(ipos)
! return the position of the last element of ivec(:) that is <= ival,
! 0 if none are >=
integer, intent(in) :: ivec(:),ival(:)
integer             :: ipos(size(ival))
integer             :: i,j,n
n    = size(ivec)
ipos = 0
do j=1,size(ival)
   do i=n,1,-1
      if (ivec(i) <= ival(j)) then
         ipos(j) = i
         exit
      end if
   end do
end do
end function last_pos_le_int_vec
!
