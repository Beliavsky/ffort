implicit none
character(:),allocatable :: x(:)
allocate(character(5)::x(2))
x='abcde'
x(2)(3:)='Q'
print '(a)',x(2)(2:)
print '(i0)',len(x(1)(:))
end
