program p
implicit none
integer::a(3)=[0,1,64]
call s(a)
contains
subroutine s(x)
integer,intent(in)::x(:)
print *,maskr(x,8)
end subroutine
end program
