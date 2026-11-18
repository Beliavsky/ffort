program p
implicit none
integer::a(2,1,2)
a=reshape([0,1,31,32],[2,1,2])
print *,maskl(a,kind=4)
end program
