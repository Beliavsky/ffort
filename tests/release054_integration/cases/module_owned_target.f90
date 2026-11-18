module m
implicit none
character(18) :: shared_name
contains
subroutine lookup(iu)
integer,intent(in) :: iu
inquire(unit=iu,name=shared_name)
end subroutine
end module
program p
use m
implicit none
integer :: iu
iu=17
! GNU_REGISTER_INPUT
call lookup(iu)
write(*,'(a)') shared_name
end program
