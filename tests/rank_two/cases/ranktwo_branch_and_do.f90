program independent_ranktwo
implicit none
integer :: aa(2,2),ii
aa=1
if (aa(2,1)==1) aa(1,2)=4
do ii=aa(1,1),aa(1,2)
 aa(2,2)=aa(2,2)+ii
end do
if (aa(2,2)>5) then
 print *,aa
else
 print *,999
end if
end program independent_ranktwo
