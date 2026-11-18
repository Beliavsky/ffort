program p
implicit none
integer(8)::a(2,2)
integer::b(2,2)
a=reshape([0_8,1_8,-1_8,4_8],[2,2])
b=leadz(a)
print *,b
print *,shape(leadz(a)),kind(leadz(a))
end program
