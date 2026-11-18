program p
implicit none
real::aa(3)
call fill(aa)
print *,aa
contains
impure elemental subroutine fill(xx)
real,intent(out)::xx
call random_number(xx)
end subroutine
end program p
