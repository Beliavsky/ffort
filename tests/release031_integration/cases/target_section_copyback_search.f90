! Synthetic release 0.31 composition fixture; not an extracted utility body.
program composition
implicit none
integer,target :: data(6)
logical,target :: mask(3)
data=[1,2,3,4,5,6]
mask=[.true.,.false.,.true.]
call change(data(6:2:-2),mask)
print *,data
print *,findloc(data,14),findloc(data(6:2:-2),12)
contains
subroutine change(x,m)
integer,target,intent(inout) :: x(:)
logical,target,intent(in) :: m(:)
x=x+10
where(m) x=x+1
print *,shape(x),sum(x),findloc(x,14)
end subroutine
end program
