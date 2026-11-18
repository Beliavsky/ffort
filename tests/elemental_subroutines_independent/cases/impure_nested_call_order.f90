program elemental_actions
implicit none
integer::aa(2)
aa(1)=2
aa(2)=5
call outer(aa)
print *,aa
contains
impure elemental subroutine outer(xx)
integer,intent(inout)::xx
call bump(xx)
call bump(xx)
end subroutine outer
impure elemental subroutine bump(xx)
integer,intent(inout)::xx
print *,xx
xx=xx+100
end subroutine bump

end program
