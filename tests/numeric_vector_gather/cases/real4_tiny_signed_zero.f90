program p
implicit none
real(4)::a(3),b(3)
a=[-0.0,tiny(0.0),0.0]
b=a([2,3,1])
if(b(1)/=tiny(0.0).or.sign(1.0,b(2))/=1.or.sign(1.0,b(3))/=-1)error stop 1
print '(i0)',1
end program
