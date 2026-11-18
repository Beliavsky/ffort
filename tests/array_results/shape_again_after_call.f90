program p
implicit none
integer::a(4),n
n=2
a=1
print *,size(f(n)),sum(f(n))
n=4
print *,size(f(n)),sum(f(n))
a(4:1:-1)=f(n)
print *,a
contains
function f(n) result(y)
integer,intent(in)::n
integer::y(n),i
do i=1,n
y(i)=i
end do
end function
end program
