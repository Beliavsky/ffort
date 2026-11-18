program p
implicit none
integer::a(2,1,2)
a=reshape([0,1,63,64],[2,1,2])
print *,maskr(a,kind=8)
end program
