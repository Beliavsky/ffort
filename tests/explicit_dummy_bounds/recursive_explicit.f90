program main
implicit none
integer::a(5)
a=[1,2,3,4,5]
print *,total(a,5),total(a,3)
contains
recursive function total(x,n) result(s)
integer,intent(in)::n
integer,intent(in)::x(n)
integer::s
if(n==0) then
s=0
else
s=x(1)+total(x(2:n),n-1)
end if
end function
end program
