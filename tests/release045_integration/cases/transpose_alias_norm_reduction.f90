program p
implicit none
real(8),allocatable::a(:,:)
real(8)::v(2)
allocate(a(2,3))
a=reshape([3d0,0d0,4d0,0d0,0d0,12d0],[2,3])
a=transpose(a)
v=norm2(a,dim=1)
print '(2i2,2f6.1)',shape(a),v
end program
