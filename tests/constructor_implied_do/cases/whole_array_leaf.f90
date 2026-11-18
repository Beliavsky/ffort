program main
implicit none
integer::i,x(3),a(8)
x=[2,4,6]
a=[(i,x,i=1,2)]
print *,a
end program
