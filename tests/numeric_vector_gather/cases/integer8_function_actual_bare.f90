program p
implicit none
integer(8)::a(3),b
a=[1,2,3]
b=total(a([3,1]))
if(b/=4)error stop 1
print '(i0)',1
contains
function total(v) result(out)
integer(8),intent(in)::v(:)
integer(8)::out
out=sum(v)
end function
end program
