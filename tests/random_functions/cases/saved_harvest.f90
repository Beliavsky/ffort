program p
implicit none
real(8)::x
x=draw()
print *, "PASS"
contains
real(8) function draw() result(r)
real(8),save::x
call random_number(x)
r=x
end function
end program
