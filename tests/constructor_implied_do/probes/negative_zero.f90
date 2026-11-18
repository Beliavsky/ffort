program main
implicit none
integer::i,a(3),b(0)
i=99
a=[(i,i=5,1,-2)]
b=[(i,i=1,3,-1)]
print *,a,i,size(b)
end program
