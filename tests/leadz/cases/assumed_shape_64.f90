program p
implicit none
integer(8)::a(3)
a=[0_8,1_8,-1_8]
call f(a)
contains
subroutine f(x)
integer(8),intent(in)::x(:)
print *,leadz(x)
end subroutine
end program
