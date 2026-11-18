program p
integer::a
a=4
call bump(a)
print *,a
contains
subroutine bump(x)
integer,intent(In OuT)::x
x=x+3
end subroutine
end program
