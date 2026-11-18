program p
implicit none
integer::a(3,2)
a=1
call take(a([3,1],:))
contains
subroutine take(x)
integer,intent(in)::x(:,:)
end subroutine
end program
