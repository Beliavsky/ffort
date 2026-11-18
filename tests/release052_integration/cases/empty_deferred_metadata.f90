program main
implicit none
character(:),allocatable::x(:),y(:)
allocate(character(5)::x(0))
y=x([integer::])
print '(i0,1x,i0,1x,i0)',size(y),len(y),kind(y)
end program
