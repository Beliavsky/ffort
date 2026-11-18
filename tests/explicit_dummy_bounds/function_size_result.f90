program main
implicit none
integer::a(5),b(3)
a=[1,2,3,40,50]
b=twice(a,3)
print *,b
contains
function twice(x,n) result(y)
integer,intent(in)::n
integer,intent(in)::x(-1:n-2)
integer::y(size(x))
y=x*2
end function
end program
