program p
implicit none
real::x,y
print *,kind(dprod(x,y)),kind(dprod([x,y],x))
end program
