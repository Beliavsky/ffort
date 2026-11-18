program p
implicit none
integer::a(3)
a=ior(draw(),1)
print *,a
contains
function draw() result(x)
integer::x(3)
real::r
call random_number(r)
x=[2,4,8]
end function
end program
