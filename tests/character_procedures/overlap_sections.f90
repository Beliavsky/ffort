program test
implicit none
character(2)::a(4)=["ab","cd","ef","gh"]
call f(a(1:2),a(3:4))
print *,a
contains
subroutine f(x,y)
character(*),intent(in)::x(:)
character(*),intent(out)::y(:)
y=x(2:1:-1)
end subroutine
end program
