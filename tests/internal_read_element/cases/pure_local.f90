program p
implicit none
integer::n
call s(n)
if(n/=71)stop 1
print '(a)', "OK"
contains
pure subroutine s(n)
integer,intent(out)::n
character(8)::a(2)
a(2)="71"
read(a(2),*)n
end subroutine
end program
