program p
implicit none
integer::a(500001)
a=1
print *,size(copy(a))
contains
function copy(x) result(y)
integer,intent(in)::x(:)
integer::y(size(x))
y=x
end function
end program
