pure function repeat_int(n,i) result(ivec)
! repeat 1-D array of integer variables with i repeated n times
integer, intent(in) :: n,i
integer             :: ivec(n)
integer             :: j
forall (j=1:n) ivec(j) = i
end function repeat_int
!
