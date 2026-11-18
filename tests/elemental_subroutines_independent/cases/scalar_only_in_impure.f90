program elemental_actions
implicit none

call announce(7)
contains
impure elemental subroutine announce(xx)
integer,intent(in)::xx
print *,xx
end subroutine announce

end program
