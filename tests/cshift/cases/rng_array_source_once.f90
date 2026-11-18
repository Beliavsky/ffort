program p
implicit none
real(8)::a(128)
a=cshift(draw(128),31)
if(any(a/=a(1))) error stop 1
if(a(1)<0d0.or.a(1)>=1d0) error stop 2
print *, "PASS"
contains
function draw(n) result(r)
integer,intent(in)::n
real(8)::r(n),x
call random_number(x)
r=x
end function
end program
