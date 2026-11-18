program main
implicit none
integer::i,a(3)
a=[(i,i=1,kind(i)+i)]
print *,a
end program
