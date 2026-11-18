! Synthetic release 0.30 composition fixture; not an extracted utility body.
program composition
implicit none
logical,allocatable :: mask(:,:,:)
call relay()
call relay(mask)
call relay(mask)
contains
subroutine relay(x)
logical,allocatable,optional,intent(in out) :: x(:,:,:)
call update(x)
end subroutine
subroutine update(x)
logical,allocatable,optional,intent(inout) :: x(:,:,:)
integer values(2,2)
print *,present(x)
if(present(x)) then
 print *,allocated(x)
 if(.not.allocated(x)) then
  allocate(x(-1:0,4:5,7:8))
  x=.false.
  x(-1,4,7)=.true.
  x(0,5,7)=.true.
  x(:,:,8)=.true.
 end if
 values=10
 where(x(:,:,7)) values=1
 print *,shape(x),lbound(x,1),lbound(x,2),lbound(x,3)
 print *,sum(values),count(x(:,:,8))
 print *,findloc(x(:,:,7),.true.),findloc(x(:,:,7),.true.,back=.true.)
 x(:,:,7)=.not.x(:,:,7)
end if
end subroutine
end program
