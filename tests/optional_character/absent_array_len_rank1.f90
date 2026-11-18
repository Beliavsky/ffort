program main
implicit none
call fail()
contains
subroutine fail(x)
character(*),optional,intent(in)::x(:)
print *,len(x)
end subroutine
end program
