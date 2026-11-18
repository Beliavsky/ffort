! Synthetic release 0.31 composition fixture; not an extracted utility body.
program composition
implicit none
logical,allocatable,target :: flags(:,:,:)
flags=make(3)
call toggle(flags,3)
print *,allocated(flags),shape(flags),count(flags(:,:,1)),count(flags(:,:,2))
print *,findloc(flags(:,:,1),.true.),findloc(flags(:,:,3),.true.,back=.true.)
contains
function make(n) result(x)
integer,intent(in),target :: n
logical,allocatable,target :: x(:,:,:)
allocate(x(2,2,n))
x=.true.
end function
recursive subroutine toggle(x,n)
logical,allocatable,target,intent(inout) :: x(:,:,:)
integer,intent(in) :: n
if(n<=0) return
x(:,:,n)=.not.x(:,:,n)
call toggle(x,n-1)
x(1,2,n)=.true.
end subroutine
end program
