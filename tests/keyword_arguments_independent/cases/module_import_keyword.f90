module work
implicit none
contains
integer function compute(alpha,beta) result(rr)
integer,intent(in) :: beta,alpha
rr=alpha-2*beta
end function
end module
program main
use work,only:compute
implicit none
print *,compute(beta=3,alpha=10)
end program
