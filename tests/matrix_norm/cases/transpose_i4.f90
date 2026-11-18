program p
implicit none
integer::a(2,3),b(3,2)
a=reshape([1,2,3,4,5,6],[2,3])
b=transpose(a)
if(any(shape(b)/=[3,2])) error stop 1
if(any(b/=reshape([1,3,5,2,4,6],[3,2]))) error stop 2
if(any(transpose(b)/=a)) error stop 3
end program
