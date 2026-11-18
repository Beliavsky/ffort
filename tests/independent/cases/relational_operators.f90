program probe
  implicit none
  integer :: a, b
  logical :: flag
  a=2
  b=3
  flag=a < b
  print *, flag, a<=b, a>b, a>=b, a==b, a/=b
end program probe
