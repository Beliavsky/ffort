program main
implicit none
integer::i,x(2,2,2),a(16)
x=reshape([1,2,3,4,5,6,7,8],[2,2,2])
a=[(x,i=1,2)]
print *,a
end program
