program elemental_actions
implicit none
integer::aa(2)
aa=9
call bump(aa)
contains
elemental subroutine bump(xx)
integer,intent(out)::xx
xx=xx+1
end subroutine bump

end program
