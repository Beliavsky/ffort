program control
implicit none
integer :: i,j,k,n
n=0
outer: do i=1,3
 middle: do j=1,4
  do k=1,5
   n=n+1
   exit middle
  end do
 end do middle
 j=99;k=98
 n=n+i
end do outer
print *,n,i,j,k
end program
