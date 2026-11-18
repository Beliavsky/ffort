program control
implicit none
integer :: i,j,n
n=0
outer: do i=1,3
 inner: do j=1,4
 if(j==2) exit outer
 n=n+1
 end do inner
end do outer
print *,n,i,j
i=7
j=8
print *,i,j
end program control
