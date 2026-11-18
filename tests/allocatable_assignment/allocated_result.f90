program probe
implicit none
integer, allocatable :: a(:)
a=make(3)
print *,lbound(a,1),ubound(a,1),a
a=make(0)
print *,allocated(a),size(a)
contains
function make(n) result(z)
integer,intent(in) :: n
integer,allocatable :: z(:)
allocate(z(-2:n-3))
z=7
end function
end program
