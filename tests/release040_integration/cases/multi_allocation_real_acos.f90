program p
implicit none
real(kind=8),allocatable::a(:),b(:)
integer::status
allocate(a(2),b(2),stat=status)
a=[-1.0_8,1.0_8]
b=acos(real(a,kind=8))
print '(i0,1x,2(l1,1x))',status,b(1)>3.14_8,b(2)==0.0_8
deallocate(a,b,stat=status)
print '(i0,1x,2(l1,1x))',status,allocated(a),allocated(b)
end program
