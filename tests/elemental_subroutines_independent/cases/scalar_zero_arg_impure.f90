program elemental_actions
implicit none

call announce()
contains
impure elemental subroutine announce()

print *,91
end subroutine announce

end program
