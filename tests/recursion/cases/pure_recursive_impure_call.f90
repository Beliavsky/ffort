program p
implicit none

print *,f(2)
contains
pure recursive integer function f(n) result(v)
integer,intent(in)::n
call a(n)
v=n
end function
recursive subroutine a(n)
integer,intent(in)::n
if(n>0) call b(n-1)
print *,n
end subroutine
recursive subroutine b(n)
integer,intent(in)::n
if(n>0) call a(n-1)
end subroutine
end program
