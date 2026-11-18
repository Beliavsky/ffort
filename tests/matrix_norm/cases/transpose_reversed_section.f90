program p
implicit none
real::a(2,3),b(3,2)
a=reshape([1,2,3,4,5,6],[2,3])
b=transpose(a(2:1:-1,3:1:-1))
if(any(b/=reshape([6,4,2,5,3,1],[3,2]))) error stop 1
end program
