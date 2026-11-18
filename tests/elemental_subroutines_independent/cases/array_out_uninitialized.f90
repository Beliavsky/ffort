program elemental_actions
implicit none
integer::aa(3)
call bump(aa)
print *,aa
contains
elemental subroutine bump(xx)
integer,intent(out)::xx
xx=7
end subroutine bump

end program
