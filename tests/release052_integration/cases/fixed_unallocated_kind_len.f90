program main
implicit none
character(6),allocatable::x(:)
integer::idx(2),n
n=0
do while(n<1)
  print '(i0,1x,i0)',len(x(idx)),kind(x(idx))
  n=n+1
end do
end program
