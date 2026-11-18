program elemental_actions
implicit none
integer::aa
aa=2
call bump(aa)
contains
impure subroutine bump(xx)
integer,intent(inout)::xx
xx=xx+1
end subroutine bump

end program
