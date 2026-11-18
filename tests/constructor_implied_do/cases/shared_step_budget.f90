program main
implicit none
integer::i,n
integer,allocatable::a(:)
n=10000
print '(a)',"before"
a=[(i,i=1,n)]
end program
