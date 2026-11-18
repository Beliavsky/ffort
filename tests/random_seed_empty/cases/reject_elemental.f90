program p
implicit none

print *,991
contains
elemental subroutine bad()
call random_seed()
end subroutine
end program
