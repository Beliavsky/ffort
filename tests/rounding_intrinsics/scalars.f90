program p
implicit none
integer, parameter :: k=8, n=nint(2.5), f=floor(-2.1), c=ceiling(2.1)
real, parameter :: l=log10(100.0)
real :: x(9)=[-2.6,-2.5,-2.4,-0.5,0.0,0.5,2.4,2.5,2.6]
real(8) :: y(9)=[-2.6d0,-2.5d0,-2.4d0,-0.5d0,0.0d0,0.5d0,2.4d0,2.5d0,2.6d0]
print *,n,f,c,l
print *,nint(x),floor(x),ceiling(x)
print *,nint(y),floor(y),ceiling(y)
print *,nint(a=x,kind=k),floor(kind=k,a=y),ceiling(a=y,kind=8_8)
print *,kind(nint(y)),kind(nint(y,8)),kind(log10(x)),kind(log10(y))
print *,log10(x=100.0),log10(x=1000.0d0)
end program
