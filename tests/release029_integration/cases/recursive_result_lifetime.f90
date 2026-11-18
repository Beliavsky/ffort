! Synthetic release 0.29 composition fixture; not an extracted utility body.
program composition
implicit none
real(8),allocatable::a(:,:,:)
a=make(2)
call bump(a,3)
print *,shape(a),lbound(a,1),lbound(a,2),lbound(a,3)
print *,sum(a(:,:,1)),sum(a(:,:,2))
a=make(0)
call bump(a,2)
print *,allocated(a),shape(a),size(a)
contains
function make(n) result(x)
integer,intent(in)::n
real(8),allocatable::x(:,:,:)
allocate(x(-1:0,4:4,7:6+n))
x=1.5d0
end function
recursive subroutine bump(x,n)
real(8),allocatable,intent(in &
 & out)::x(:,:,:)
integer,intent(in)::n
integer::dims(3)
dims=shape(x)
if(n>0) then
 x=x+1.0d0
 call bump(x,n-1)
end if
if(n==0) print *,dims
end subroutine
end program
