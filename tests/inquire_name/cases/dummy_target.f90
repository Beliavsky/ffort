module m
contains
subroutine q(iu,nm)
integer,intent(in)::iu
character(*),intent(out)::nm
inquire(unit=iu,name=nm)
end subroutine
end module
program p
use m
implicit none
integer::iu
character(24)::nm
iu=17
! GNU_REGISTER_INPUT
call q(iu,nm)
write(*,'(a)') '['//nm//']'
end program
