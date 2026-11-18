program probe
  implicit none
  integer :: x
  x=1
  print *, "SHOULD_NOT_EXECUTE"
  write (*,*) x
end program probe
