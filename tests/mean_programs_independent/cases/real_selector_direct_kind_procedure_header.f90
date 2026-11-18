program p
implicit none

print *,identity(1.125d0)
contains
real(kind=kind(1d0)) function identity(xx) result(yy)
real(kind=kind(1d0)),intent(in)::xx
yy=xx
end function
end program p
