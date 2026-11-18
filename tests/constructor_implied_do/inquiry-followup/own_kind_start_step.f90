program main
implicit none
integer::i,a(3)
a=[(i,i=kind(i),3*kind(i),kind(i))]
print *,a
end program
