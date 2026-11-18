program p
implicit none
integer::n
call s(n)
if(n/=67)stop 1
print '(a)', "OK"
contains
subroutine s(n)
integer,intent(out)::n
character(8)::a(2)
a(2)="67"
read(a(2),*)n
end subroutine
end program
