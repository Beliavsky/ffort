implicit none
character(:),allocatable::x(:)
allocate(character(3)::x(2))
x=['abc','def']
print '(a)',x([2,1])
end
