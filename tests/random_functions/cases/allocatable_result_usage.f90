program p
implicit none
real(8),allocatable::x(:)
allocate(x(7))
x=draw()
if(any(x/=x(1))) error stop 1
deallocate(x)
print *, "PASS"
contains
real(8) function draw() result(r)
call random_number(r)
end function
end program
