program p
implicit none
integer::a(3,2)
call f((a([1,2],:)))
contains
subroutine f(x)
integer,intent(inout)::x(:,:)
end subroutine
end program
