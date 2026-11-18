program p
implicit none
real::a(2,2,2)
a=2.0
print *,dprod(a,2.0),shape(dprod(a,a))
end program
