program elemental_actions
implicit none

print *,991
call bump(2)
contains
elemental subroutine bump(xx)
integer,intent(inout)::xx
xx=xx+1
end subroutine bump

end program
