program control
implicit none
integer :: i,j,n
n=0
outer: do i=1,4
 do j=1,3
 select case(i)
 case(1)
 cycle outer
 case(3)
 exit outer
 case default
 n=n+1
 end select
 end do
end do outer
print *,n,i,j
end program control
