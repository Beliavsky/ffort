program control
implicit none
integer :: i,j,k,n
n=0
outer: do i=1,3
 middle: do j=1,4
  do k=1,5
   n=n+1
   cycle outer
  end do
 end do middle
end do outer
print *,n,i,j,k
j=99;k=98
print *,j,k
end program
