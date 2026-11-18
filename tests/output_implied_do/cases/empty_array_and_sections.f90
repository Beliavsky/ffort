program main
implicit none
integer::i
integer::a(0),b(3)
b=[1,2,3]
print *, -1,(a,b(2:1),i=1,3),-2
print *,i
end program
