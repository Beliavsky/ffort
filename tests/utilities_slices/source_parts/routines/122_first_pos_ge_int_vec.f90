pure function first_pos_ge_int_vec(ivec,ival) result(ipos)
! return the position of the first element of ivec(:) that is >= ival,
! n+1 if none are >= ival
integer, intent(in) :: ivec(:),ival(:)
integer             :: ipos(size(ival))
integer             :: i,j,n
n    = size(ivec)
ipos = n+1
do j=1,size(ival)
   do i=1,n
      if (ivec(i) >= ival(j)) then
         ipos(j) = i
         exit
      end if
   end do
end do
end function first_pos_ge_int_vec
!
