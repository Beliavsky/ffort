program control
implicit none
integer :: i,j,n
do i=-2,3
 n=99
 if(i<0) then
   n=-10
 else if(i==0) then
   n=10
   n=n+1
 elseif(i==1) then
   n=20
   n=n+2
 else
   n=30
   n=n+3
 endif
 print *,i,n
end do
end program control
