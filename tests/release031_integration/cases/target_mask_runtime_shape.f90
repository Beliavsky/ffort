! Synthetic release 0.31 composition fixture; not an extracted utility body.
program composition
implicit none
integer,target,allocatable :: data(:)
logical,target,allocatable :: keep(:)
allocate(data(3))
allocate(keep(2));data=1;keep=.true.
call inspect(data,keep)
contains
subroutine inspect(x,m)
integer,allocatable,target,intent(in) :: x(:)
logical,allocatable,target,intent(in) :: m(:)
integer :: positions(1)
positions=findloc(x,1,mask=m)
print *,positions
end subroutine
end program
