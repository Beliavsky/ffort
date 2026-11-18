module composition
implicit none
contains
subroutine host()
character(15)::char
character(30)::record
char='char(n) says hi'
call patch()
call show()
contains
subroutine patch()
char(9:12)='asks'
end subroutine
subroutine show()
write(record,'(2(a))')'"',char
write(*,'("char(n) [",a,"] [",a,"]")')char,trim(record)
end subroutine
end subroutine
end module
program main
use composition
implicit none
call host()
end program
