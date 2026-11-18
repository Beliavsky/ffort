program p
implicit none
real(8)::a(3),b(3)
a=[-0.0_8,tiny(0.0_8),0.0_8]
b=a([2,3,1])
if(b(1)/=tiny(0.0_8).or.sign(1.0_8,b(2))/=1.or.sign(1.0_8,b(3))/=-1)error stop 1
print '(i0)',1
end program
