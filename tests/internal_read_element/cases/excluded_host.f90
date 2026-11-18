program p
implicit none
character(20)::lines(3)
integer::n,i,ios
lines="17"
call s(n)
contains
subroutine s(x)
integer,intent(out)::x
read(lines(1),*)x
end subroutine
end program
