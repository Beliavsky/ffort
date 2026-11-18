program p
implicit none
integer,parameter::dp=kind(1d0)
real(dp),parameter::pi=acos(-1.0_dp)
print *,pi,kind(pi)
end program
