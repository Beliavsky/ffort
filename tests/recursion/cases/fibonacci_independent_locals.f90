program p
implicit none

print *,fib(9)
contains
pure integer recursive function fib(n) result(v)
integer,intent(in)::n
integer::left,right
if(n<2) then
v=n
else
left=fib(n-1)
right=fib(n-2)
v=left+right
end if
end function
end program
