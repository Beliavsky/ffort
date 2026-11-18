program main
implicit none
integer::i,x(2),a(6)
x=[1,2]
a=[(x+i,i=1,3)]
print *,a
end program
