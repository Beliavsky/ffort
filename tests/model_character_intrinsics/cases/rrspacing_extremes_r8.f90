program p
implicit none
real(8)::x
x=nearest(0.0_8,1.0_8)
if(rrspacing(x)/=2.0_8**52)error stop 1
if(rrspacing(huge(x))/=(2.0_8**53-1.0_8))error stop 2
print *,rrspacing(x),rrspacing(-x),rrspacing(huge(x)),rrspacing(tiny(x))
end program
