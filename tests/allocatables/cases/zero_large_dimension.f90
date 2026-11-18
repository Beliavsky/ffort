program main
implicit none
integer,allocatable::a(:,:)
allocate(a(0,2147483647))
print *,allocated(a),size(a),size(a,2)
end program
