program p
implicit none
real(4)::x(2),v,expected
x=[3.0e-30_4,4.0e-30_4]
expected=5.0e-30_4
v=norm2(x)
if(v<=0.0_4.or.abs(v/expected-1.0_4)>16*epsilon(v)) error stop 1
end program
