program p
implicit none
integer(8)::a(3)
a=[0_8,16_8,-16_8]
print *,f(a)
contains
function f(x) result(y)
integer(8),intent(in)::x(:)
integer::y(size(x))
y=trailz(x)
end function f
end program p
