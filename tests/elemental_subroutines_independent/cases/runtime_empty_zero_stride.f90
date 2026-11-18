program elemental_actions
implicit none
integer::aa(0),stride
stride=0
call bump(aa(1:0:stride))
contains
impure elemental subroutine bump(xx)
integer,intent(inout)::xx
print *,xx
xx=xx+100
end subroutine bump

end program
