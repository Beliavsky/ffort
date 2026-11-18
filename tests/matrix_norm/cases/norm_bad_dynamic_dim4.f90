program p
implicit none
real::x(2,2,2)
integer(8)::d
x=1
d=4
print *,norm2(x,d)
end program
