program main
implicit none
call f()
contains
subroutine f(x)
integer,optional,intent(in)::x(:,:)
call required(x)
end subroutine
subroutine required(x)
integer,intent(in)::x(:,:)
end subroutine
end program
