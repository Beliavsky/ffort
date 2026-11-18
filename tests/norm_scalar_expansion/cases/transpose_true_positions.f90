program main
implicit none
real::x(2,3),a(3,2)
x=reshape([1.,2.,3.,4.,5.,6.],[2,3])
a=transpose(x)
if(any(a/=reshape([1.,3.,5.,2.,4.,6.],[3,2]))) error stop 1
end program
