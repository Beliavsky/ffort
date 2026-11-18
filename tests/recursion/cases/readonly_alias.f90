program p
integer::x(2)
x=[2,3]
print *,f(3,x,x)
contains
recursive integer function f(n,a,b) result(v)
integer,intent(in)::n,a(:),b(:)
if(n==0) then
v=sum(a)+sum(b)
else
v=f(n-1,a,a)+sum(b)
end if
end function
end program
