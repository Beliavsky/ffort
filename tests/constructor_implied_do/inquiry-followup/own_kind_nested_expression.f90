program main
implicit none
integer::i,a(4)
a=[(i,i=1,kind(i+1))]
print *,a
end program
