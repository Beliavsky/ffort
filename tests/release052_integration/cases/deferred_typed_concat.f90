program main
implicit none
character(:),allocatable::x(:)
character(4)::y(3)
allocate(character(2)::x(2))
x=['a ','b ']
y=[character(4)::x([2,1]),'Z']
print '(a)',y
end program
