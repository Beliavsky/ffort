program main
implicit none
real::x(2,3,4)
integer(8)::d
d=0
print *,ubound(x,dim=d)
end program
