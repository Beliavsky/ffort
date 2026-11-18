program p
implicit none
real(8)::x(100)
x=draw(100)
print *, "PASS"
contains
function draw(n) result(r)
integer,intent(in)::n
real(8)::r(n)
call random_number(r)
end function
end program
