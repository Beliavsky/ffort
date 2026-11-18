program main
implicit none
integer(8)::i,a(3)
a=[(i,i=digits(i)-2,digits(i))]
print *,a
end program
