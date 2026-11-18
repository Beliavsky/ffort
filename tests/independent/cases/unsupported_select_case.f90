program probe
  implicit none
  integer :: x
  x=1
  select case (x)
  case (1)
   print *, x
  end select
end program probe
