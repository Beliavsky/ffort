program combined
implicit none
real(8),allocatable::a(:)
a=values()
print '(2f9.4)',a,sinh(a),cosh(a)
contains
function values() result(v)
real(8),allocatable::v(:)
v=[0.0_8,0.5_8]
end function
end program
