program p
implicit none
call s(maskr(2_8,8))
contains
subroutine s(x)
integer(8),intent(in)::x
print *,x,kind(x)
end subroutine
end program
