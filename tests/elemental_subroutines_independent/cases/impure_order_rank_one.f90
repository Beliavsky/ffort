program elemental_actions
implicit none
integer::aa(3)
aa(1)=2
aa(2)=4
aa(3)=6
call bump(aa)
print *,aa
contains
impure elemental subroutine bump(xx)
integer,intent(inout)::xx
print *,xx
xx=xx+100
end subroutine bump

end program
