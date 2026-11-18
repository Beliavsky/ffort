program p
implicit none
print *,double(1),precision(2),doubleprecision(3)
contains
integer function double(x)
integer,intent(in)::x
double=x+1
end function
function precision(x) result(y)
integer,intent(in)::x
integer::y
y=x+2
end function
function doubleprecision(x)
integer,intent(in)::x
integer::doubleprecision
doubleprecision=x+3
end function
end program
