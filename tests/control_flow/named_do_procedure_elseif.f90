module probes
implicit none
contains
function score(a) result(value)
integer,intent(in)::a(:)
integer(8)::value,j
value=0_8
if(a(1)<0) then
 value=-1_8
else if(a(1)>0) then
 outer: do j=1_8,int(size(a),kind=8)
  if(a(j)==3) cycle outer
  if(a(j)>4) exit outer
  value=value+int(a(j),kind=8)
 end do outer
 value=value+10_8
else
 value=-2_8
end if
end function
end module
program control
use probes
implicit none
print *,score([1,3,5,7]),score([-1,3]),score([0,3]),score([1,2,3,4])
end program
