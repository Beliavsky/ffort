! Synthetic release 0.31 composition fixture; not an extracted utility body.
program composition
implicit none
character(3),target :: words(3)
character(3),target :: query
logical,allocatable,target :: keep(:)
words=['red','tan','red'];query='red'
keep=[.true.,.true.,.true.]
call relay(words,keep)
call relay(words,keep,query)
contains
subroutine relay(x,m,value)
character(*),target,intent(in) :: x(:)
logical,allocatable,target,intent(in) :: m(:)
character(*),target,optional,intent(in) :: value
call inspect(x,m,value)
end subroutine
subroutine inspect(x,m,value)
character(*),target,intent(in) :: x(:)
logical,allocatable,target,intent(in) :: m(:)
character(*),optional,target,intent(in) :: value
character(len=len(x(1))),target :: local
print *,present(value),len(local),shape(x)
if(present(value)) then
 local=value
 print *,len(value),findloc(x,local,mask=m),findloc(x,local,mask=m,back=.true.)
end if
end subroutine
end program
