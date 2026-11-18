program p
integer::a,b
a=2
b=f(a)
print *,b
contains
integer function f(x) result(v)
integer,intent(in out)::x
x=x+1
v=x
end function
end program
