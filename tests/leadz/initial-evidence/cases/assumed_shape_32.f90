program p
implicit none
integer(4)::a(3)
a=[0_4,1_4,-1_4]
call f(a)
contains
subroutine f(x)
integer(4),intent(in)::x(:)
print *,leadz(x)
end subroutine
end program
