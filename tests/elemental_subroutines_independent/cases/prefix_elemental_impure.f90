program elemental_actions
implicit none
integer::aa(3)
aa=2
call bump(aa)
print *,aa
contains
elemental impure subroutine bump(xx)
integer,intent(inout)::xx
xx=xx+1
end subroutine bump

end program
