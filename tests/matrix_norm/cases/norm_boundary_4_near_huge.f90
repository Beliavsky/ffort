program p
implicit none
real(4)::x(2),scale,v,expected
scale=huge(0.0_4)/4.0_4
x=[scale,scale]
expected=scale*sqrt(2.0_4)
v=norm2(x)
if(v<=0.0_4.or.abs(v/expected-1.0_4)>32*epsilon(v)) error stop 1
end program
