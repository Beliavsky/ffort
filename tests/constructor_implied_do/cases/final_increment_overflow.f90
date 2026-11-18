program main
implicit none
integer::i,a(1),lo
print '(a)',"before"
lo=2147483647
a=[(i,i=lo,lo)]
end program
