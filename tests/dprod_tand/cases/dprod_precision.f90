program p
implicit none
real::x=1.00000011920928955078125
print *,dprod(x,x),dble(x)*dble(x),kind(dprod(x,x))
end program
