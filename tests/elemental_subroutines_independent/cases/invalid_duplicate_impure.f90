program elemental_actions
implicit none
integer::aa
print *,991
aa=2
call bump(aa)
contains
impure impure elemental subroutine bump(xx)
integer,intent(inout)::xx
xx=xx+1
end subroutine bump

end program
