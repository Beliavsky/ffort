program p
implicit none
integer,parameter::a(3,2)=reshape([1,2,3,4,5,6],[3,2])
integer::b(2,2)
b=a([3,1],:)
print *,b
end program
