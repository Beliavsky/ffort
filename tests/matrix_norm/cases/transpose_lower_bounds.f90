program p
implicit none
real::a(-1:0,4:6),b(3,2)
a=reshape([1,2,3,4,5,6],[2,3])
b=transpose(a)
if(any(b/=reshape([1,3,5,2,4,6],[3,2]))) error stop 1
end program
