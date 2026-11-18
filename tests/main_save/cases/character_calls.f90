module m
implicit none
contains
subroutine change(a)
character(len=*),intent(inout)::a(:)
a='xy'
end subroutine
end module
program p
use m
implicit none
character(len=3),save::a(2)=[character(len=3)::'A','B']
call change(a)
print *,all(a=='xy ')
end program
