program probe
  implicit none
  integer :: x
  real :: y
  x=int(-3.75)
  y=real(7)
  print *, x, y, mod(-7,3), mod(7,-3), mod(-7.5,3.0)
end program probe
