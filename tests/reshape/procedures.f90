module m
implicit none
contains
function vec() result(v)
integer::v(2)
v=[4,5]
end function
impure elemental integer function extent(x)
integer,intent(in)::x
print *,20
extent=x
end function
subroutine take(a)
integer,intent(in)::a(:,:)
print *,a
end subroutine
end module
program p
use m
implicit none
integer::a(2,2),pad(-2:-1,3:4),sh(1),u(1)
real::r(2,2)
pad(:,3)=[6,7]
pad(:,4)=[8,9]
a=reshape(vec(),[extent(2),2],pad=pad,order=[2,1])
print *,a
call take(reshape([1,2,3,4],[2,2]))
r=reshape([1.5,2.5],[2,2],pad=[3.5],order=[2,1])
print *,r
print *,reshape(reshape([1,2,3,4],[2,2],order=[2,1]),[4],order=[1])
print *,kind(reshape(u,sh)),lbound(reshape(a,[4]),1),ubound(reshape(a,[4]),1)
end program
