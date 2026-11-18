program main
implicit none
real,allocatable::a(:)
allocate(a(3))
print *,size(a),allocated(a),kind(a)
deallocate(a)
end program
