program main
implicit none
real,allocatable::a(:),b(:,:,:)
print *,minexponent(a),maxexponent(b)
allocate(a(0))
allocate(b(2,3,1))
print *,minexponent(a),maxexponent(b)
end program
