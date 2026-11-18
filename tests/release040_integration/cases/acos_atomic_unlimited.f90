program p
implicit none
real(kind=8) :: a(2)
a=[0.0_8,2.0_8]
print '(a)','before'
print '(*(g0,1x))',acos(a)
end program
