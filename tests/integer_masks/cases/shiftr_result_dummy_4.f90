program p
implicit none
call s(shiftr(-1_4,1_8))
contains
subroutine s(x)
integer(4),intent(in)::x
print *,x,kind(x)
end subroutine
end program
