program p
implicit none
character(8)::a(1)
integer::n
a="17"
call s(a,n)
contains
subroutine s(x,n)
character(*),intent(in)::x(:)
integer,intent(out)::n
read(x(1),*)n
end subroutine
end program
