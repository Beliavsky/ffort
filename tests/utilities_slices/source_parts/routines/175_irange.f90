pure function irange(i1,i2) result(ivec)
! return an array of consecutive integers from i1 to i2, including both endpoints
integer, intent(in) :: i1,i2
integer             :: ivec(max(0,i2-i1+1))
integer             :: i
do i=i1,i2
   ivec(i-i1+1) = i
end do
end function irange
!
