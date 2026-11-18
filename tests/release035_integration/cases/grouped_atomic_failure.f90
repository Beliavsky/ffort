module composition
implicit none
contains
subroutine host(values)
integer,intent(in)::values(:)
write(*,'(a)')'before grouped child'
call child()
contains
subroutine child()
write(*,'(a,2(i0),a)')'must not leak',values,'done'
end subroutine
end subroutine
end module
program main
use composition
implicit none
call host([12,34,56])
end program
