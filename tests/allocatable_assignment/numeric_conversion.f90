program probe
implicit none
real(8), allocatable :: a(:)
integer, allocatable :: b(:)
a=[1,2,3]
b=a+0.5_8
print *,kind(a),kind(b),a,b
end program
