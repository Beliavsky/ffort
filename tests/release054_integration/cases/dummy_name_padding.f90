module m
implicit none
contains
subroutine lookup(iu,name)
integer(8),intent(in) :: iu
character(*),intent(out) :: name
inquire(unit=iu,name=name)
end subroutine
end module
program p
use m
implicit none
integer(8) :: iu
character(17) :: long_name
character(5) :: short_name
iu=17_8
! GNU_REGISTER_INPUT
call lookup(iu,long_name)
iu=18_8
call lookup(name=short_name,iu=iu)
write(*,'(a,a,a,a,a)') '[',long_name,']|[',short_name,']'
end program
