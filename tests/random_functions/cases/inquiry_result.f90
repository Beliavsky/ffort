program p
implicit none
integer::n
n=size(draw(3))
if(n/=3) error stop 1
print *, "PASS"
contains
function draw(n) result(r)
integer,intent(in)::n
real(8)::r(n)
call random_number(r)
end function
end program
