program elemental_actions
implicit none
integer::aa
print *,991
aa=2
call bump(aa)
contains
elemental subroutine bump(xx)
integer,intent(inout)::xx
print *,xx
end subroutine bump

end program
