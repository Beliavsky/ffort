! Synthetic release 0.31 composition fixture; not an extracted utility body.
program composition
implicit none
character(8),target :: label
label='x'
call relay(label)
call relay(label,3)
print '(a)',label
contains
subroutine relay(x,n)
character(*),target,intent(inout) :: x
integer,optional,intent(in) :: n
call expand(x,n)
end subroutine
subroutine expand(x,n)
character(*),target,intent(inout) :: x
integer,optional,intent(in) :: n
print *,present(n),len(x)
if(present(n)) call step(x,n)
end subroutine
recursive subroutine step(x,n)
character(*),target,intent(inout) :: x
integer,intent(in) :: n
if(n<=0) return
x=repeat(trim(x),2)
call step(x,n-1)
end subroutine
end program
