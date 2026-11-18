program p
integer,allocatable::a(:)
a=[1,2]
call bump(a)
print *,a
contains
subroutine bump(x)
integer,allocatable,intent(in out)::x(:)
x=[x,3]
end subroutine
end program
