program p
implicit none
real(8)::empty(0),z(2)
z=-0.0d0
print '(3es25.17)',norm2(empty),norm2(z),-0.0d0
end program
