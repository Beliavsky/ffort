program main
implicit none
character(1)::x(3)
integer::i
x=['a','b','c']
i=9
print '(a)',(x([i,4-i]),i=1,3)
print '(i0)',i
end program
