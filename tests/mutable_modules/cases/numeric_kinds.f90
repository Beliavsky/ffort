module state
implicit none
integer(8)::counter=2147483648_8
real(8)::value=0.5_8
logical::flag=.false.
contains
subroutine change()
counter=counter+1_8
value=value*2.0_8
flag=.true.
end subroutine
end module
program main
use state
implicit none
call change()
print *,counter,value,flag
end program
