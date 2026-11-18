program main
implicit none
integer::i,n,empty(0)
integer,allocatable::a(:)
n=1000001
print '(a)',"before"
a=[(empty,i=1,n)]
print *,size(a)
end program
