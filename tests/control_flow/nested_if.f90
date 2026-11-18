program control
implicit none
integer :: i,j,n
do i=0,3
 if(i==0) then
 n=0
 else if(i<3) then
 if(i==1) then
 n=10
 else if(i==2) then
 n=20
 else
 n=30
 end if
 else
 n=40
 end if
 print *,n
end do
end program control
