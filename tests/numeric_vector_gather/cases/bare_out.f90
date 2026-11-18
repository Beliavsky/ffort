program p
implicit none
integer::a(3)
a=1
call take(a([3,1]))
contains
subroutine take(x)
integer,intent(out)::x(:)
end subroutine
end program
