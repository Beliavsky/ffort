program elemental_actions
implicit none
integer::aa(30)
aa=1
call bump(aa)
print *,aa
contains
elemental subroutine bump(xx)
integer,intent(inout)::xx
xx=xx+1
end subroutine bump

end program
