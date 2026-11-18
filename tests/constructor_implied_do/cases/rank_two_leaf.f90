program main
implicit none
integer::i,x(2,3),a(12)
x=reshape([1,2,3,4,5,6],[2,3])
a=[(x,i=1,2)]
print *,a
end program
