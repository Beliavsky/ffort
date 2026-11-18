program elemental_actions
implicit none
integer::aa(2)
aa(1)=3
aa(2)=7
call bump(aa)
print *,aa
contains
impure elemental subroutine bump(xx)
integer,intent(inout)::xx
call ordinary(xx)
end subroutine bump
 subroutine ordinary(xx)
integer,intent(inout)::xx
print *,xx
xx=xx+1
end subroutine ordinary

end program
