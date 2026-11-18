program p
print *,f(4)
contains
function f(n) result(v)
integer,intent(in)::n
integer v,i,a(n)
a=n
v=0
do i=1,n
v=v+a(i)
end do
end function
end program
