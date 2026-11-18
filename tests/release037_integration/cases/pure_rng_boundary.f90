program main
implicit none
real::x
x=draw()
contains
pure function draw() result(x)
real::x
call random_number(x)
end function
end program
