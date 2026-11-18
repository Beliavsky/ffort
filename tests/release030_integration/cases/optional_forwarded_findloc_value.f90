! Synthetic release 0.30 composition fixture; not an extracted utility body.
program composition
implicit none
logical,allocatable :: a(:)
call relay()
call relay(a)
a=[.false.,.true.,.false.,.true.]
call relay(a)
call relay(a,.true.)
call relay(a,.false.)
contains
subroutine relay(x,value)
logical,allocatable,optional,intent(in) :: x(:)
logical,optional,intent(in) :: value
call inspect(x,value)
end subroutine
subroutine inspect(x,value)
logical,allocatable,optional,intent(in) :: x(:)
logical,optional,intent(in) :: value
print *,present(x),present(value)
if(present(x)) then
 print *,allocated(x)
 if(allocated(x)) then
  print *,shape(x)
  if(present(value)) print *,findloc(x,value,dim=1),findloc(x,value,dim=1,back=.true.)
 end if
end if
end subroutine
end program
