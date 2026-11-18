program main
implicit none
integer::a(2,2)
a=1
call change((a([2,1],:)))
contains
subroutine change(x)
integer,intent(inout)::x(:,:)
x=2
end subroutine
end program
