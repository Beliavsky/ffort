program p
implicit none
real(8)::a(2),b(2)
a=[1d0,2d0]
b=a+norm2([3d0,4d0],dim=1)
print '(4es25.17)',b,norm2([-0d0]),-0d0
end program
