program p
implicit none
real(8)::aa(5)=-1d0
call fill(aa(1:5:2))
print *,aa
contains
subroutine fill(xx)
real(8),intent(inout)::xx(:)
call random_number(xx)
end subroutine
end program p
