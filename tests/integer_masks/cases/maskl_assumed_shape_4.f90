program p
implicit none
integer::a(3)=[0,1,32]
call s(a)
contains
subroutine s(x)
integer,intent(in)::x(:)
print *,maskl(x,4)
end subroutine
end program
