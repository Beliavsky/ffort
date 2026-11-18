program p
implicit none
integer::a(3),empty(0)
a=[1,2,3]
call take(a(empty),a)
contains
subroutine take(x,y)
integer,intent(in)::x(:)
integer,intent(out)::y(:)
y=9
end subroutine
end program
