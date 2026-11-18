program main
implicit none
integer,allocatable::a(:)
integer::n
n=3
print *, allocated(a),kind(a)
allocate(a(-2:n-3))
a=[4,5,6]
print *, allocated(array=a),size(a),lbound(a,1),ubound(a,1),sum(a),a(-1)
deallocate(a)
print *,allocated(a)
allocate(a(1))
a=9
print *,a(1)
end program
