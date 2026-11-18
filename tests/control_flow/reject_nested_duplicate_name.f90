program control
implicit none
integer :: i,j,n
print *,123
outer: do i=1,2
outer: do j=1,2
end do outer
end do outer
end program control
