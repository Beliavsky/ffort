program p
implicit none
real(8),parameter::a(4)=[1.,2.,3.,4.]
real(8)::b(3)
b=a([4,1,4])
if(any(b/=[4,1,4]))error stop 1
print '(i0)',1
end program
