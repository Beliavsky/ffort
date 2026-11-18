program p
implicit none
real::a(0,2,3)
print *,size(dprod(a,huge(1.0))),kind(dprod(a,a))
end program
