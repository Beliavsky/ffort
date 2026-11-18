program main
implicit none
integer::i,n
integer,allocatable::a(:)
print '(a)',"before"
a=[(i,i=1,n)]
end program
