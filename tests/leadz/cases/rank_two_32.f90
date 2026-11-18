program p
implicit none
integer(4)::a(2,2)
integer::b(2,2)
a=reshape([0_4,1_4,-1_4,4_4],[2,2])
b=leadz(a)
print *,b
print *,shape(leadz(a)),kind(leadz(a))
end program
