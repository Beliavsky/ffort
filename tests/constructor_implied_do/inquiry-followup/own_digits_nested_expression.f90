program main
implicit none
integer::i,a(3)
a=[(i,i=digits(i+1)-2,digits(i+1))]
print *,a
end program
