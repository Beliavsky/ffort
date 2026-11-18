program main
implicit none
integer::i,j,a(3)
a=[(i,i=1,size([(j,j=1,i)]))]
end program
