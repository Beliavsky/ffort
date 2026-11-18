program p
implicit none
integer::n
call s(n)
contains
subroutine s(n)
integer,intent(out)::n
character(8),save::a(1)
a(1)="17"
read(a(1),*)n
end subroutine
end program
