program p
implicit none
real::a(2,2)
a=reshape([1.,2.,3.,4.],[2,2])
print *,dprod(a,2.0),dprod(a,a)
end program
