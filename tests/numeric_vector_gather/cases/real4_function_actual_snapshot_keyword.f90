program p
implicit none
real(4)::a(3),b
a=[1,2,3]
b=total(v=(a([3,1])))
if(b/=4)error stop 1
print '(i0)',1
contains
function total(v) result(out)
real(4),intent(in)::v(:)
real(4)::out
out=sum(v)
end function
end program
