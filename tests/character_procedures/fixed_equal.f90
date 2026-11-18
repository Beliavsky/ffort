program test
implicit none
character(2)::a(2)=["ab","cd"]
call f(a)
print *,a
contains
subroutine f(x)
character(2),intent(inout)::x(:)
x=x(2:1:-1)
end subroutine
end program
