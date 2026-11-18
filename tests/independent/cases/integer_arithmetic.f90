program probe
  implicit none
  integer :: a, b, c
  a=7
  b=3
  c=a+b*2
  print *, c, (a+b)*2, a/b, (-a)/b, a/(-b)
end program probe
