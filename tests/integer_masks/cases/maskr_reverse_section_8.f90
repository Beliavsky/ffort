program p
implicit none
integer::a(5)=[0,1,2,63,64]
print *,maskr(a(5:1:-2),kind=8)
end program
