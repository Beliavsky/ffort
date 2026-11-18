! Synthetic release 0.31 composition fixture; not an extracted utility body.
program composition
implicit none
logical,target,allocatable :: active(:,:,:)
call relay()
call relay(active)
call relay(active)
contains
subroutine relay(x)
logical,target,optional,allocatable,intent(inout) :: x(:,:,:)
call change(x)
end subroutine
subroutine change(x)
logical,allocatable,target,optional,intent(inout) :: x(:,:,:)
integer,target :: values(2,2)
print *,present(x)
if(present(x)) then
 print *,allocated(x)
 if(.not.allocated(x)) then
  allocate(x(-2:-1,5:6,9:9))
  x=.false.
  x(-2,6,9)=.true.
 end if
 values=4
 where(x(:,:,9)) values=9
 print *,shape(x),lbound(x,1),lbound(x,2),lbound(x,3),sum(values)
 print *,findloc(x(:,:,9),.true.),findloc(x(:,:,9),.false.,back=.true.)
 x=.not.x
end if
end subroutine
end program
