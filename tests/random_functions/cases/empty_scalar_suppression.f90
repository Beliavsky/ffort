program p
implicit none
real(8)::x(0)
x=0d0
x=x+draw()
print *, "PASS"
contains
real(8) function draw() result(r)
call random_number(r)
error stop "empty path evaluated"
end function
end program
