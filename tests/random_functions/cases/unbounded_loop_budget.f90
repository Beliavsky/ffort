program p
implicit none
real(8)::x
x=draw()
print *, "PASS"
contains
real(8) function draw() result(r)
do
call random_number(r)
end do
end function
end program
