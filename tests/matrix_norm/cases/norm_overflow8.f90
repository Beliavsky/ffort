program p
implicit none
real(8)::x(2)
x=huge(0.0_8)
print *,norm2(x)
end program
