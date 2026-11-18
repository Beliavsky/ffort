program main
implicit none
integer::i
integer::a(5)
a=[10,20,30,40,50]
print *, (a(i:1:-1),i=1,5)
end program
