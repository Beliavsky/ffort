program p
logical,allocatable::a(:),b(:,:)
call inspect()
call inspect(a,b)
allocate(a(-1:0));a=.true.
allocate(b(3:4,7:8));b=.false.
call inspect(a,b)
contains
subroutine inspect(x,y)
logical,allocatable,optional,intent(in)::x(:),y(:,:)
print *,present(x),present(y)
if(present(x)) then
print *,allocated(x)
if(allocated(x)) print *,lbound(x,1),x
end if
if(present(y)) then
print *,allocated(y)
if(allocated(y)) print *,lbound(y,1),lbound(y,2),y
end if
end subroutine
end program
