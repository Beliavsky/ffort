program elemental_actions
implicit none
integer::aa(2)
print *,991
aa=2
call bump(aa+1)
contains
elemental subroutine bump(xx)
integer,intent(out)::xx
xx=3
end subroutine bump

end program
