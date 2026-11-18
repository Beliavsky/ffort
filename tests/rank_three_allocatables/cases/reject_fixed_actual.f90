program p
integer::a(1,1,1)
call bad(a)
contains
subroutine bad(x)
integer,allocatable,intent(inout)::x(:,:,:)
x=2
end subroutine
end program
