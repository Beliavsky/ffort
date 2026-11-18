program p
integer,allocatable::a(:,:,:)
allocate(a(-1:0,3:3,7:8)); a=2
call inspect(a)
call replace(a)
call inspect(a)
call grow(a)
call inspect(a)
contains
subroutine inspect(x)
integer,allocatable,intent(in)::x(:,:,:)
integer::total,k
total=0
do k=lbound(x,3),ubound(x,3)
total=total+sum(x(:,:,k))
end do
print *,allocated(x),lbound(x,1),lbound(x,2),lbound(x,3),size(x),total
end subroutine
subroutine replace(x)
integer,allocatable,intent(out)::x(:,:,:)
print *,allocated(x)
allocate(x(2:2,-3:-2,8:10)); x=5
end subroutine
subroutine grow(x)
integer,allocatable,intent(inout)::x(:,:,:)
call nested(x)
end subroutine
subroutine nested(x)
integer,allocatable,intent(inout)::x(:,:,:)
deallocate(x)
allocate(x(-4:-3,6:6,0:0)); x=9
end subroutine
end program
