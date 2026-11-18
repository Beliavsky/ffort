program elemental_actions
implicit none
integer::aa(2)
print *,991
aa=2
call announce(aa)
contains
impure elemental subroutine announce(xx)
integer,intent(in)::xx
print *,xx
end subroutine announce

end program
