program p
logical,allocatable::a(:,:,:)
allocate(a(-1:0,4:4,7:8));a=.true.
call inspect(a)
call replace(a)
call modify(a)
call inspect(a)
contains
subroutine inspect(x)
logical,allocatable,intent(in)::x(:,:,:)
print *,allocated(x),lbound(x,1),lbound(x,3),x
end subroutine
subroutine replace(x)
logical,allocatable,intent(out)::x(:,:,:)
print *,allocated(x)
allocate(x(3:3,4:4,-2:-1));x=.false.
end subroutine
subroutine modify(x)
logical,allocatable,intent(inout)::x(:,:,:)
call nested(x)
end subroutine
subroutine nested(x)
logical,allocatable,intent(inout)::x(:,:,:)
x=.not.x
end subroutine
end program
