program p
implicit none
integer::a(2,2)
a=reshape([0,1,63,64],[2,2])
print *,maskl(a,kind=8)
end program
