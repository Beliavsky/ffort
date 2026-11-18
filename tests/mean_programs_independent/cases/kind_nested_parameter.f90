program p
implicit none
integer,parameter::dp=kind(1d0),n=kind(dp)
real(dp)::aa(n)=[1.0_dp,2.0_dp,3.0_dp,4.0_dp]
print *,dp,n,kind(aa),sum(aa)
end program p
