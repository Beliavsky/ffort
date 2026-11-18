program elemental_actions
implicit none
integer::aa(3)
aa=1
call outer(aa)
print *,aa
contains
elemental subroutine outer(xx)
integer,intent(inout)::xx
call bump(xx)
call bump(xx)
end subroutine outer
elemental subroutine bump(xx)
integer,intent(inout)::xx
xx=xx+1
end subroutine bump

end program
