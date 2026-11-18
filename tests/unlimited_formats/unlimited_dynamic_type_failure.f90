program p
implicit none
real,allocatable::x(:)
allocate(x(2))
x=1.
write(*,'("prefix",*(i0))')x
end program
