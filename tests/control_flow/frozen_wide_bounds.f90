program control
implicit none
integer(8) :: i,n,lo,hi,step
lo=1;hi=5;step=2
n=0
do i=lo,hi,step
 lo=20;hi=30;step=-10
 n=n+i
end do
print *,n,i,lo,hi,step
end program control
