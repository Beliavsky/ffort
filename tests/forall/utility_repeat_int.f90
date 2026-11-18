program p
implicit none
integer,parameter::dp=kind(1.0d0)

print *,repeat_int(4,7),size(repeat_int(0,7))
contains
pure function repeat_int(n,i) result(ivec)
! repeat 1-D array of integer variables with i repeated n times
integer, intent(in) :: n,i
integer             :: ivec(n)
integer             :: j
forall (j=1:n) ivec(j) = i
end function repeat_int
end program
