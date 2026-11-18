program p
implicit none
real(8)::x
x=draw()
print *, "PASS"
contains
impure real(8) function draw() result(r)
call random_number(r)
end function
end program
