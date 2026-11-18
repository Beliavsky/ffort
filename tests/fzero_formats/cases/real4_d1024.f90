implicit none
real(kind=4) :: x(8)
x = [1.0, -1.0, 0*1.0, -0.0*1.0, 0.125*1.0, -0.125*1.0, huge(1.0), -huge(1.0)]
print '(f0.1024)', x
end
