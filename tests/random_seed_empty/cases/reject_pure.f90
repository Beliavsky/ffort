program p
implicit none

print *,991
contains
pure subroutine bad()
call random_seed()
end subroutine
end program
