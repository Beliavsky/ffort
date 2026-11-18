program p
implicit none
integer,allocatable::a(:,:)
a=reshape([1,2,3,4,5,6],[2,3])
a=transpose(a)
if(any(shape(a)/=[3,2])) error stop 1
if(any(a/=reshape([1,3,5,2,4,6],[3,2]))) error stop 2
end program
