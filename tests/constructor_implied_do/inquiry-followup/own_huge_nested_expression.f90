program main
implicit none
integer::i,a(2)
a=[(i,i=huge(i+1)-2,huge(i+1)-1)]
print *,a
end program
