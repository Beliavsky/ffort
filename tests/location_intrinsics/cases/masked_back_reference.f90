program main
implicit none
integer::a(2,2),i,j,best,loc(2)
a=reshape([4,-1,2,2],[2,2])
best=999
loc=0
do j=1,2
 do i=1,2
  if(a(i,j)<=0) cycle
  if(a(i,j)<=best) then
   best=a(i,j)
   loc=[i,j]
  end if
 end do
end do
print *,loc
end program
