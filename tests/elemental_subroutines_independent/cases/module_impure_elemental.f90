module actions
implicit none
contains
impure elemental subroutine step(xx)
integer,intent(inout)::xx
print *,xx
xx=xx+1
end subroutine
end module
program main
use actions,only:step
implicit none
integer::aa(2)
aa=5
call step(aa)
print *,aa
end program
