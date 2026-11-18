program elemental_actions
implicit none
integer::aa(3)
call bump(aa)
print *,aa
contains
elemental subroutine bump(xx)
integer,intent(inout)::xx
xx=8
end subroutine bump

end program
