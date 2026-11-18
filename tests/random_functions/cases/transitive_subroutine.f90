program p
implicit none
real(8)::a(20)
a=draw()
if(any(a/=a(1))) error stop 1
print *, "PASS"
contains
real(8) function draw() result(r)
call helper(r)
end function
subroutine helper(x)
real(8),intent(out)::x
call random_number(x)
end subroutine
end program
