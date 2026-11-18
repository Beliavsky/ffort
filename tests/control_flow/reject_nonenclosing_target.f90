program control
implicit none
integer :: i,j,n
print *,123
first: do i=1,2
end do first
do i=1,2
cycle first
end do
end program control
