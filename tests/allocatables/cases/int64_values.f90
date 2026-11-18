program main
implicit none
integer(8),allocatable::a(:)
allocate(a(2))
a=[2147483648_8,2147483649_8]
print *,sum(a),kind(a)
end program
