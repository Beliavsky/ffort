program p
implicit none
real::x(-1:0,5:7),y(3)
x=reshape([1.,2.,3.,4.,5.,6.],[2,3])
y=norm2(x(0:-1:-1,7:5:-1)+0.,dim=1)
if(any(abs(y-sqrt([61.,25.,5.]))>2e-6)) error stop 1
end program
