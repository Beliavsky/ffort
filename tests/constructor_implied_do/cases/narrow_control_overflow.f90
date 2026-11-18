program main
implicit none
integer::i,a(1)
integer(8)::lo
print '(a)',"before"
lo=2147483648_8
a=[(i,i=lo,lo)]
end program
