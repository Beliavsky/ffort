program elemental_actions
implicit none
integer::aa
print *,991
aa=2
call outer(aa)
contains
elemental subroutine outer(xx)
integer,intent(inout)::xx
call bump(xx)
end subroutine outer
impure elemental subroutine bump(xx)
integer,intent(inout)::xx
print *,xx
xx=xx+100
end subroutine bump

end program
