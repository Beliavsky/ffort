program main
implicit none
integer::i,n
integer,allocatable::a(:)
n=500000
a=[([1,1],i=1,n)]
print *,size(a),sum(a)
end program
