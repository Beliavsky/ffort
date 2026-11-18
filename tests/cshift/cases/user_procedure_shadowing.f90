program p
implicit none
integer::a(3)
a=cshift([1,2,3],1)
if(any(a/=[2,3,4])) error stop 1
print *, "PASS"
contains
function cshift(a,n) result(r)
integer,intent(in)::a(:),n
integer::r(size(a))
r=a+n
end function
end program
