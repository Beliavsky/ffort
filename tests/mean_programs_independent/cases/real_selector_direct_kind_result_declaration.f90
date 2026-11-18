program p
implicit none

print *,identity(1.125d0)
contains
function identity(xx) result(yy)
real(kind=kind(1d0)),intent(in)::xx
real(kind=kind(1d0))::yy
yy=xx
end function
end program p
