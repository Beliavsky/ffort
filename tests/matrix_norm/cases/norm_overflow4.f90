program p
implicit none
real(4)::x(2)
x=huge(0.0_4)
print *,norm2(x)
end program
