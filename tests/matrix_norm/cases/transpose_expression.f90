program p
implicit none
real(8)::a(2,3),b(3,2)
a=reshape([1d0,2d0,3d0,4d0,5d0,6d0],[2,3])
b=transpose(a+10d0)
if(any(b/=reshape([11d0,13d0,15d0,12d0,14d0,16d0],[3,2]))) error stop 1
end program
