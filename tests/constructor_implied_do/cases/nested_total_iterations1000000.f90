program main
implicit none
integer::i,j,n,empty(0)
integer,allocatable::a(:)
n=499999
print '(a)',"before"
a=[((empty,j=1,n),i=1,2)]
print *,size(a)
end program
