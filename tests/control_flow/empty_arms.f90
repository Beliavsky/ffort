program control
implicit none
integer :: i,j,n
do i=0,3
 n=5
 if(i==0) then
 else if(i==1) then
 else if(i==2) then
 n=7
 else
 endif
 print *,n
enddo
end program control
