program p
implicit none
real(8)::x
x=draw()
print *, "PASS"
contains
real(8) function draw() result(r)
call random_number(r)
print *,r
end function
end program
