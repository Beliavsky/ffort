program elemental_actions
implicit none
integer::aa(3),n
aa=2
n=4
call bump(aa(1:n))
contains
impure elemental subroutine bump(xx)
integer,intent(inout)::xx
print *,xx
xx=xx+100
end subroutine bump

end program
