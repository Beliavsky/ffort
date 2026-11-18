program p
implicit none
integer,parameter::a(2,3)=reshape([1,2,3,4,5,6],[2,3])
integer,parameter::b(3,2)=transpose(a)
if(any(b/=reshape([1,3,5,2,4,6],[3,2]))) error stop 1
end program
