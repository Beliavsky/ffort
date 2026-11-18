program p
integer::a
a=4
call bump(a,a)
print *,a
contains
subroutine bump(x,y)
integer,intent(in out)::x,y
x=x+y
end subroutine
end program
