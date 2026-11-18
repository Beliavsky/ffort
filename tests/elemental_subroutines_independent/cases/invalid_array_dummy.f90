program elemental_actions
implicit none
integer::aa(2)
print *,991
call bump(aa)
contains
elemental subroutine bump(xx)
integer,intent(inout)::xx(:)
xx=xx+1
end subroutine bump

end program
