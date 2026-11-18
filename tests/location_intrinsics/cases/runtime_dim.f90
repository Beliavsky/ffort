module locations
implicit none
contains
function locate(a,d) result(x)
integer,intent(in)::a(:,:),d
integer::x(size(a,3-d))
x=minloc(a,d)
end function
end module
program p
use locations
implicit none
integer::a(2,3),d
a=reshape([3,1,5,4,2,6],[2,3])
d=1
print *,locate(a,d)
d=2
print *,locate(a,d)
end program
