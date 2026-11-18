program p
implicit none
real(8),save :: a(-1:0)=1.5_8
a=a+0.5_8
print *, all(a==2.0_8)
end program
