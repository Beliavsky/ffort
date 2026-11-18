module constants
implicit none
integer,parameter::dp=kind(1d0)
contains
function convert(i) result(x)
integer,intent(in)::i
real(dp)::x
x=real(i,dp)
end function
end module
program p
use constants
implicit none
print *,convert(17),kind(real(1,dp))
end program
