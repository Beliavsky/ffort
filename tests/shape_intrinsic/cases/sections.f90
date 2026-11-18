program p
implicit none
integer::a(-2:3,0:4,2:5)
a=0
print *,shape(a(-2:3:2,4:0:-2,2:5:2))
print *,shape(a(0,:,3)),shape(a(:,2,:)),shape(a(2,2,2))
print *,shape(a(2:1,:,:))
end program
