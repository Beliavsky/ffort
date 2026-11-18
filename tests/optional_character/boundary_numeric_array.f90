program main
implicit none
call fail()
contains
subroutine fail(x)
integer,optional,intent(in)::x(:)
end subroutine
end program
