program p
implicit none
real(8)::x
x=draw()
print *, "PASS"
contains
real(8) function draw() result(r)
real(8),save::x
call helper(x)
r=x
end function
subroutine helper(x)
real(8),intent(out)::x
call random_number(x)
end subroutine
end program
