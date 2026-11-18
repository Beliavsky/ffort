program p
implicit none
integer(8)::a(2,1,2)
integer::b(2,1,2)
a(:,:,1)=reshape([0_8,1_8],[2,1])
a(:,:,2)=reshape([-1_8,4_8],[2,1])
b=leadz(a)
print *,b,shape(leadz(a)),kind(leadz(a))
end program
