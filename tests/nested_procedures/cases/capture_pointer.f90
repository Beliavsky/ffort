module m
implicit none
contains
subroutine host()
integer,target::x(2)
integer,pointer::q(:)
x=1
q=>x
call child()
contains
subroutine child()
print *,associated(q)
end subroutine
end subroutine
end module
program p
use m
implicit none
call host()
end program
