program main
implicit none
integer::i,j,a(4)
a=[(i,i=1,kind([(j,j=1,i)]))]
print *,a
end program
