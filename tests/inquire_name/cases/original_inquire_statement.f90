module m
contains
subroutine q(iu)
integer,intent(in)::iu
character(len=1000)::file_name
inquire (unit=iu,name=file_name)
write(*,'(a)') trim(file_name)
end subroutine
end module
program p
use m
integer::iu
iu=17
! GNU_REGISTER_INPUT
call q(iu)
end program
