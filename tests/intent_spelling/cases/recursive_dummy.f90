program p
integer::a
a=1
call bump(3,a)
print *,a
contains
pure recursive subroutine bump(n,x)
integer,intent(in)::n
integer,intent(in out)::x
x=x+n
if(n>0) call bump(n-1,x)
end subroutine
end program
