program p
implicit none
integer::a(3)
a=f()
print *,a
contains
function f() result(x)
integer::x(3),i
x=[1,2,3]
forall(i=1:3)
x(i)=x(4-i)
end forall
end function
end program
