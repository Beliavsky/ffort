program main
implicit none
integer::i,j,a(4)
a=[(i,i=1,size([(j,j=1,kind(i))]))]
print *,a
end program
