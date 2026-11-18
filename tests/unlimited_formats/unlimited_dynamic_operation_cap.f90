program p
implicit none
integer,allocatable::x(:)
allocate(x(20000))
x=1
write(*,'(*(10(""),i0))')x
end program
