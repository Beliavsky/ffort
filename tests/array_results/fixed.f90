module m
implicit none
contains
pure function vector(x) result(y)
integer,intent(in)::x
integer::y(-1:1)
y=[x,x+1,x+2]
end function
end module
program p
use m
implicit none
integer::a(3)
a=vector(3)
print *,a,vector(5),sum(vector(4)),size(vector(9)),lbound(vector(3),1)
end program
