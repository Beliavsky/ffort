program p
implicit none
call s(shiftr(-1_8,1_8))
contains
subroutine s(x)
integer(8),intent(in)::x
print *,x,kind(x)
end subroutine
end program
