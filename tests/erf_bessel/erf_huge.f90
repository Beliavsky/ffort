program p
implicit none
real(8)::x
x=huge(x)
print *,erf(x),erf(-x)
end program
