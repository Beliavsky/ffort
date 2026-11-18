program bits_driver
implicit none
integer::a(6),b(3),c(3)
a=[1,2,3,4,5,6]
b=[7,0,2]
c=iand(a(6:1:-2),b)
print *,c
end program
