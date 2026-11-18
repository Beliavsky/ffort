program control
implicit none
integer :: i,j,n
n=0
do i=1,5
 if(i==2) cycle
 do j=1,4
 if(j==3) exit
 n=n+i+j
 end do
 if(i==4) exit
end do
print *,n,i,j
i=99
j=98
print *,i,j
end program control
