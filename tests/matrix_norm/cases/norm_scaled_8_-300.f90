program p
implicit none
real(8)::x(2),v,expected
x=[3.0e-300_8,4.0e-300_8]
expected=5.0e-300_8
v=norm2(x)
if(v<=0.0_8.or.abs(v/expected-1.0_8)>16*epsilon(v)) error stop 1
end program
