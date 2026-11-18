program p
implicit none
integer::a(5)=[0,1,2,31,32]
print *,maskl(a(5:1:-2),kind=4)
end program
