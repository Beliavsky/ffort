program p
implicit none

print *,fact(6),fact(0),fact(5)
contains
recursive pure integer function fact(n) result(v)
integer,intent(in)::n
if(n<=1) then
v=1
else
v=n*fact(n-1)
end if
end function
end program
