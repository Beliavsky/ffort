program probe
implicit none
integer,parameter :: n=max(2,abs(-4)), m=mod(n+1,3)
real,parameter :: r=real(n)/2.0
print*,n,m,r
end program probe
