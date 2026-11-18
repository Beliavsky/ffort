program p
implicit none
integer(8)::a(4),b(3)
a=[1,2,3,4]
b=pick(a)
if(any(b/=[4,1,4]))error stop 1
print '(i0)',1
contains
function pick(x) result(y)
integer(8),intent(in)::x(:)
integer(8)::y(3)
y=x([4,1,4])
end function
end program
