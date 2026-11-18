program test
implicit none
real(8)::t
call q(t)
print *,"PASS"
contains
subroutine q(t)
real(8),intent(out)::t
call cpu_time(t)
end subroutine
end program
