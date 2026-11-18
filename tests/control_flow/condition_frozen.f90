program control
implicit none
integer :: i,j,n
n=0
do i=1,4
 if(i==1) then
 n=n+1
 elseif(i==2) then
 n=n+10
 else if(i==3) then
 n=n+100
 else
 n=n+1000
 end if
end do
print *,n,i
end program control
