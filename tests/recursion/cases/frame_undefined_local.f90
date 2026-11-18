program p
implicit none

call bad(1)
contains
recursive subroutine bad(n)
integer,intent(in)::n
integer::saved
if(n>0) then
saved=99
call bad(n-1)
else
print *,saved
end if
end subroutine
end program
