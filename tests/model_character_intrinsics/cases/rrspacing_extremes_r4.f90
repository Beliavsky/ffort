program p
implicit none
real(4)::x
x=nearest(0.0_4,1.0_4)
if(rrspacing(x)/=2.0_4**23)error stop 1
if(rrspacing(huge(x))/=(2.0_4**24-1.0_4))error stop 2
print *,rrspacing(x),rrspacing(-x),rrspacing(huge(x)),rrspacing(tiny(x))
end program
