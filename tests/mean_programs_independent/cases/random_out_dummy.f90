program p
implicit none
real(8)::aa(3)
call fill(aa)
print *,aa
contains
subroutine fill(xx)
real(8),intent(out)::xx(:)
call random_number(xx)
end subroutine
end program p
