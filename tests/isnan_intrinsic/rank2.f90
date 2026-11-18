program p
implicit none
real::x(3,2)
logical::y(3,2)
x=reshape([1.,2.,3.,4.,5.,6.],[3,2])
y=isnan(x)
print *,shape(y),y
end program
