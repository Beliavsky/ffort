! Synthetic release 0.31 composition fixture; not an extracted utility body.
program composition
implicit none
logical,target,allocatable :: a(:),b(:)
allocate(a(-3:-2))
allocate(b(8:10))
a=.true.;b=[.false.,.true.,.false.]
a=[.false.,.true.]
print *,lbound(a,1),shape(a),findloc(a,.true.)
a=b
print *,lbound(a,1),shape(a),findloc(a,.false.,back=.true.)
call reset(a)
print *,allocated(a)
contains
subroutine reset(x)
logical,target,allocatable,intent(out) :: x(:)
print *,allocated(x)
allocate(x(-1:0));x=.true.
print *,lbound(x,1),shape(x),findloc(x,.true.,back=.true.)
deallocate(x)
end subroutine
end program
