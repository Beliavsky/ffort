program p
implicit none
call s(maskl(2_8,4))
contains
subroutine s(x)
integer(4),intent(in)::x
print *,x,kind(x)
end subroutine
end program
