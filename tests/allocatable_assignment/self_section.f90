program probe
implicit none
integer, allocatable :: a(:)
a=[1,2,3]
a=a(2:)
print *,size(a),a
end program
