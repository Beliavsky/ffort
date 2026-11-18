program elemental_actions
implicit none
integer,parameter::aa=2
print *,991
call bump(aa)
contains
elemental subroutine bump(xx)
integer,intent(out)::xx
xx=3
end subroutine bump

end program
