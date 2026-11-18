program main
implicit none
integer::i,j,a(2)
a=[(i,i=1,len([("ab",j=1,i)]))]
print *,a
end program
