program p
implicit none
real(8)::x
x=pure_draw()
print *, "PASS"
contains
pure real(8) function pure_draw() result(r)
r=draw()
end function
real(8) function draw() result(r)
call random_number(r)
end function
end program
