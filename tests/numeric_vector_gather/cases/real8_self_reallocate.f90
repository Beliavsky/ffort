program p
implicit none
real(8),allocatable::a(:)
a=[1.,2.,3.,4.]
a=a([4,2,2])
if(size(a)/=3.or.any(a/=[4,2,2]))error stop 1
print '(i0)',1
end program
