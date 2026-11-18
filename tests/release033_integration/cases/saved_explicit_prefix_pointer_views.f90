! Synthetic release 0.33 composition fixture; original bodies, if any, are separate.
module m
implicit none
contains
pure integer function span(n) result(v)
integer,intent(in)::n
v=n+1
end function
subroutine update(x,n)
integer,intent(in)::n
integer,target,intent(inout)::x(0:n)
integer::temporary(span(n))
integer,save::visits=0
visits=visits+1
temporary=x+10*visits
x=temporary
print *,visits,size(x),lbound(x,1)
end subroutine
end module
program main
use m
implicit none
integer,target::a(8)
integer,pointer::p(:)
a=[1,2,3,4,5,6,7,8]
p=>a(8:2:-2)
call update(a(8:2:-2),1)
call update(a(1:5:2),2)
print *,a,p,findloc(p,16),shape(p)
end program
