program p
implicit none
print *,f(5),f(0)
contains
recursive integer function f(n) result(v)
integer,intent(in)::n
do
if(n==0) then
v=1
exit
end if
v=n*f(n-1)
exit
end do
end function
end program
