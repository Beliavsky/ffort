program p
implicit none

print *,fact(3)
contains
recursive pure integer function fact(n) result(v)
integer,intent(in)::n
integer::saved=0
if(n<=1) then
v=1
else
v=n*fact(n-1)
end if
end function
end program
