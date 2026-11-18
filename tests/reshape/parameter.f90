program p
implicit none
integer,parameter::a(2,2)=reshape([1,2,3,4],[2,2],order=[2,1])
integer,parameter::b(4)=reshape(a,[4])
print *,a,b
end program
