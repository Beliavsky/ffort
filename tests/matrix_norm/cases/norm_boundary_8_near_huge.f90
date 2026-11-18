program p
implicit none
real(8)::x(2),scale,v,expected
scale=huge(0.0_8)/4.0_8
x=[scale,scale]
expected=scale*sqrt(2.0_8)
v=norm2(x)
if(v<=0.0_8.or.abs(v/expected-1.0_8)>32*epsilon(v)) error stop 1
end program
