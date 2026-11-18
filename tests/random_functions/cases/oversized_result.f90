program p
implicit none
real(8)::x
x=sum(draw(1000001))
print *, "PASS"
contains
function draw(n) result(r)
integer,intent(in)::n
real(8)::r(n)
call random_number(r)
end function
end program
