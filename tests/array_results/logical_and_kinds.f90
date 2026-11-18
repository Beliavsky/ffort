program p
implicit none
logical::m(3)
m=positive([-1,2,0])
print *,m,count(positive([-1,2,3])),wide(2),kind(wide(0)),dbl(2)
contains
pure function positive(x) result(y)
integer,intent(in)::x(:)
logical::y(size(x))
y=x>0
end function
pure function wide(n) result(y)
integer,intent(in)::n
integer(8)::y(n)
y=9007199254740993_8
end function
pure function dbl(n) result(y)
integer,intent(in)::n
real(8)::y(n)
y=1.2345678901234567d0
end function
end program
