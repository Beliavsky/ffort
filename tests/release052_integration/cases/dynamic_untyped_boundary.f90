program main
implicit none
character(:),allocatable::x(:)
allocate(character(2)::x(2))
x=['ab','cd']
write(*,'(a)',advance='no')'SAFE'
print '(a)',[x([2,1])]
end program
