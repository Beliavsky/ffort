program p
implicit none
integer(4)::a(2)=[-1_4,1_4]
call s(a)
contains
subroutine s(x)
integer(4),intent(in)::x(:)
print *,shiftr(x,1)
end subroutine
end program
