program probe
implicit none
integer,parameter :: a=7, b=4, c=a*a+b, d=c**3, e=mod(d,c)
integer :: x=d
print*,a,b,c,d,e,x
end program probe
