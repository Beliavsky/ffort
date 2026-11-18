program p
implicit none
integer::k
k=kind(draw(3))
if(k/=8) error stop 1
print *, "PASS"
contains
function draw(n) result(r)
integer,intent(in)::n
real(8)::r(n)
call random_number(r)
error stop "KIND evaluated array function"
end function
end program
