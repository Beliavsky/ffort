program p
implicit none
integer::n
call s(2,n)
contains
subroutine s(k,n)
integer,intent(in)::k
integer,intent(out)::n
character(8)::a(k)
a(1)="17"
read(a(1),*)n
end subroutine
end program
