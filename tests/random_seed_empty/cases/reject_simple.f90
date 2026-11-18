program p
implicit none

print *,991
contains
simple subroutine bad()
call random_seed()
end subroutine
end program
