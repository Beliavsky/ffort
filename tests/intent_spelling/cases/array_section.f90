program p
integer::a(4)
a=[1,2,3,4]
call bump(a(4:1:-2))
print *,a
contains
subroutine bump(x)
integer,intent(in out)::x(:)
x=x+10
end subroutine
end program
