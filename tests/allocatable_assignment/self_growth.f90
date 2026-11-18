program probe
implicit none
integer, allocatable :: a(:)
a=[1,2]
a=[a,3]
print *,size(a),a
end program
