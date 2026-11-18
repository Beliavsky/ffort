program p
integer::a(3)=[3,4,3]
print *,f(findloc(a,3)),g(findloc(a,3,1,back=.true.))
contains
integer function f(x) result(y)
integer,intent(in)::x(:)
y=sum(x)
end function
integer function g(x) result(y)
integer,intent(in)::x
y=x
end function
end program
