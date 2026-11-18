program elemental_actions
implicit none
integer::aa(0,3)
call bump(aa)
print *,size(aa)
contains
impure elemental subroutine bump(xx)
integer,intent(inout)::xx
print *,xx
xx=xx+100
end subroutine bump

end program
