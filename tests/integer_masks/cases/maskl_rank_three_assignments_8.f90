program p
implicit none
integer::a(2,1,2)
a(1,1,1)=0
a(2,1,1)=1
a(1,1,2)=63
a(2,1,2)=64
print *,maskl(a,kind=8)
end program
