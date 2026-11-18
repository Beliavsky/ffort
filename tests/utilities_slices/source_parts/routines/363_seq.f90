function seq(n) result(ivec)
! return a sequence of integers from 1 to n
integer, intent(in) :: n
integer             :: ivec(n)
integer             :: i
ivec = [(i,i=1,n)]
end function seq
!
