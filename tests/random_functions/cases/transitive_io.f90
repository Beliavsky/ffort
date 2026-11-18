program p
implicit none
real(8)::x
x=draw()
print *, "PASS"
contains
real(8) function draw() result(r)
call helper(r)
end function
subroutine helper(r)
real(8),intent(out)::r
call random_number(r)
print *,r
end subroutine
end program
