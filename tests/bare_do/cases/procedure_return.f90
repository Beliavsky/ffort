program p
implicit none

print *,f(3),f(5)
contains
integer function f(k) result(v)
integer,intent(in)::k
integer::n
v=0
n=0
do
n=n+1
v=v+n
if(n==k) return
end do
end function
end program
