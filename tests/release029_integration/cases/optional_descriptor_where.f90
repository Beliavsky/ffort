! Synthetic release 0.29 composition fixture; not an extracted utility body.
program composition
implicit none
integer,allocatable::a(:,:,:)
call relay()
call relay(a)
call relay(a)
contains
subroutine relay(x)
integer,allocatable,optional,intent(in & ! continued direction

 ! Deliberately keep a comment-only physical line.
 & out)::x(:,:,:)
call update(x)
end subroutine
subroutine update(x)
integer,allocatable,optional,intent(in out)::x(:,:,:)
print *,present(x)
if(present(x)) then
 print *,allocated(x)
 if(.not.allocated(x)) then
  allocate(x(-1:0,4:5,7:8))
  x=2
 end if
 where(x(:,:,7)>=2) x(:,:,7)=x(:,:,7)+3
 print *,shape(x),lbound(x,1),lbound(x,2),lbound(x,3)
 print *,sum(x(:,:,7)),sum(x(:,:,8))
end if
end subroutine
end program
