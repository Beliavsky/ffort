program p
implicit none
integer::i
real(8)::x
i=-(+3)+(-2)**2
x=-2.0_8**2
if(i/=1.or.x/=-4.0_8) error stop 1
print *, 'unary signs' 
end program
