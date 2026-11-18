program p
implicit none
real(8)::a(3),b
a=[1,2,3]
b=total(v=(a([3,1])))
if(b/=4)error stop 1
print '(i0)',1
contains
function total(v) result(result_value)
real(8),intent(in)::v(:)
real(8)::result_value
result_value=sum(v)
end function
end program
