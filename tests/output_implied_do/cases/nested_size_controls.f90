program main
implicit none
integer::i,j,a(3)
a=[10,20,30]
print *, ((a(j),j=1,size(a(:i))),i=1,size(a))
end program
