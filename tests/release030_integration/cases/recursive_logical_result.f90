! Synthetic release 0.30 composition fixture; not an extracted utility body.
program composition
implicit none
logical,allocatable :: a(:,:,:)
a=make_mask(2)
call flip(a,3)
print *,shape(a),lbound(a,3),count(a(:,:,1)),count(a(:,:,2))
print *,findloc(a(:,:,1),.true.),findloc(a(:,:,2),.true.,back=.true.)
a=make_mask(0)
print *,allocated(a),shape(a),size(a)
contains
function make_mask(n) result(x)
integer,intent(in) :: n
logical,allocatable :: x(:,:,:)
allocate(x(2,1,n))
x=.true.
end function
recursive subroutine flip(x,n)
logical,allocatable,intent(inout) :: x(:,:,:)
integer,intent(in) :: n
if(n<=0) return
x(:,:,1)=.not.x(:,:,1)
call flip(x,n-1)
end subroutine
end program
