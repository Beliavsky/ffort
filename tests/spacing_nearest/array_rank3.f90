program p
implicit none

real::a(2,1,2),b(2,1,2)
a=1;b=spacing(a)
print *,shape(b),b==epsilon(1.)
b=nearest(a,1d0)
print *,b>a
end program
