program p
implicit none
real(8)::x(16)
call inspect(draw())
print *, "PASS"
contains
real(8) function draw() result(r)
call random_number(r)
end function
subroutine inspect(a)
real(8),intent(in)::a
real(8)::x(16)
x=a
if(any(x/=a)) error stop 1
end subroutine
end program
