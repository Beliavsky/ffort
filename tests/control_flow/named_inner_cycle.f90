program control
implicit none
integer :: i,j,n
n=0
outer: do i=1,2
 inner: do j=1,4
 if(j==2) cycle inner
 if(j==4) exit inner
 n=n+i+j
 end do inner
end do outer
print *,n,i,j
end program control
