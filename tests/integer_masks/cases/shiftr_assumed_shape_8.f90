program p
implicit none
integer(8)::a(2)=[-1_8,1_8]
call s(a)
contains
subroutine s(x)
integer(8),intent(in)::x(:)
print *,shiftr(x,1)
end subroutine
end program
