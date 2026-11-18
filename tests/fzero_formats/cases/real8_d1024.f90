implicit none
real(kind=8) :: x(8)
x = [1.0d0, -1.0d0, 0*1.0d0, -0.0*1.0d0, 0.125*1.0d0, -0.125*1.0d0, huge(1.0d0), -huge(1.0d0)]
print '(f0.1024)', x
end
