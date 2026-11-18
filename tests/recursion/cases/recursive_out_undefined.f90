program p
implicit none
integer::x
call bad(1,x)
print *,x
contains
recursive subroutine bad(n,x)
integer,intent(in)::n
integer,intent(out)::x
if(n>0) then
x=99
call bad(n-1,x)
end if
end subroutine
end program
