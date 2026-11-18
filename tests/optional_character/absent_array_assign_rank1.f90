program main
implicit none
call fail()
contains
subroutine fail(x)
character(*),optional,intent(out)::x(:)
x='bad'
end subroutine
end program
