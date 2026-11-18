program p
implicit none
integer::a(2,1,2)
a(1,1,1)=0
a(2,1,1)=1
a(1,1,2)=31
a(2,1,2)=32
print *,maskl(a,kind=4)
end program
