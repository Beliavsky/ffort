program main
implicit none
integer::i,a(3)
a=[(i,i=digits(i)-2,digits(i))]
print *,a
end program
