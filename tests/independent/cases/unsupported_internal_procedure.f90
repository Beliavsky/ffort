program probe
implicit none
print *, twice(2)
contains
integer function twice(x)
integer, intent(in) :: x
twice=2*x
end function twice
end program probe
