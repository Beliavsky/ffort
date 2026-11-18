program elemental_actions
implicit none
integer::aa(3,4)
aa=0
call bump(aa(2,4:1:-1))
print *,aa
contains
elemental subroutine bump(xx)
integer,intent(inout)::xx
xx=xx+1
end subroutine bump

end program
