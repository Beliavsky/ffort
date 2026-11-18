program elemental_test
implicit none
integer::aa(2)
aa=2
call bump(aa)
print *,aa
contains
elemental subroutine bump(xx)
integer,intent(inout)::xx
xx=xx+1
end subroutine
end program
