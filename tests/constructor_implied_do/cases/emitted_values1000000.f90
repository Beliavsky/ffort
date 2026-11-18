program main
implicit none
integer::i,n,x(2)
integer,allocatable::a(:)
n=500000
x=1
print '(a)',"before"
a=[(x,i=1,n)]
print *,size(a),sum(a)
end program
