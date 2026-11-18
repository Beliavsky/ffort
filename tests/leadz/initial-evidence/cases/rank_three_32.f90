program p
implicit none
integer(4)::a(2,1,2)
integer::b(2,1,2)
a(:,:,1)=reshape([0_4,1_4],[2,1])
a(:,:,2)=reshape([-1_4,4_4],[2,1])
b=leadz(a)
print *,b,shape(leadz(a)),kind(leadz(a))
end program
