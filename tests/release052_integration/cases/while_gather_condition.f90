program main
implicit none
character(1)::x(3)
integer::n
x=['a','b','c']
n=0
do while(any(x([1,3])/=['b','a']))
  x=x([2,3,1])
  n=n+1
end do
print '(i0,1x,3a1)',n,x
end program
