program main
implicit none
integer::i,x(4),a(10)
x=[10,20,30,40]
a=[(x(i:1:-1),i=1,4)]
print *,a
end program
