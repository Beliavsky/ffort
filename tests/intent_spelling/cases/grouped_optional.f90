program p
integer::a,b
a=4
b=9
call bump(a,b)
print *,a
contains
subroutine bump(x,y)
integer,intent(in out),optional::x,y
x=x+y
y=y+1
end subroutine
end program
