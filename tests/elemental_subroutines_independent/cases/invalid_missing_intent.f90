program elemental_actions
implicit none
integer::aa
print *,991
call bump(aa)
contains
elemental subroutine bump(xx)
integer::xx
xx=xx+1
end subroutine bump

end program
