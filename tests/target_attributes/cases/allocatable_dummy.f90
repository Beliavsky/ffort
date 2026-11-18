program p
integer,target,allocatable::a(:,:,:)
call setup(a)
call inspect(a)
call change(a)
print *,a
contains
subroutine setup(x)
integer,target,allocatable,intent(out)::x(:,:,:)
allocate(x(1,1,2));x=4
end subroutine
subroutine inspect(x)
integer,allocatable,intent(in),target::x(:,:,:)
print *,allocated(x),x
end subroutine
subroutine change(x)
integer,intent(inout),target,allocatable::x(:,:,:)
x=x+1
end subroutine
end program
