program main
implicit none
real::x
x=draw()
contains
function draw() result(x)
real::x
print *,1
x=0.0
end function
end program
