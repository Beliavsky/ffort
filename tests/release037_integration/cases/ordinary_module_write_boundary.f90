module state
implicit none
integer::counter=0
contains
function draw() result(x)
real::x
counter=counter+1
call random_number(x)
end function
end module
program main
use state
implicit none
real::x
x=draw()
write(*,'(i0)')counter
end program
