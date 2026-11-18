program p
implicit none
integer,parameter::dp=kind(1.0d0),sp=dp/2
real(dp),parameter::a=real(7,dp),b=real(a=a+1,kind=sp)
real,parameter::c=real(16777217)
integer,parameter::k=kind(real(1d0)),j=kind(real(1,dp))
print *,a,b,c,k,j
print *,c==16777216.0
end program p
