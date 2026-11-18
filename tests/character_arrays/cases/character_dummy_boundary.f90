program p
implicit none
character(2)::a(2)="x"
call f(a)
contains
subroutine f(x)
character(2),intent(in)::x(:)
print *,x
end subroutine
end
