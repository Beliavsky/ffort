program p
implicit none
real(8)::x
x=draw(12)
if(x<0d0.or.x>=13d0) error stop 1
print *, "PASS"
contains
recursive function draw(n) result(r)
integer,intent(in)::n
real(8)::r,t
call random_number(t)
r=t
if(n>0) r=r+draw(n-1)
end function
end program
