program probe
implicit none
integer,allocatable :: a(:)
allocate(a(100000))
a=2
a=[1,2,3]
print *,size(a),a
end program
