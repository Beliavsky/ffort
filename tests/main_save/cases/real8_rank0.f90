program p
implicit none
real(8),save :: a=1.5_8
a=a+0.5_8
print *, a==2.0_8
end program
