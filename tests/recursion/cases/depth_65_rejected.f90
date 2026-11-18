program p
implicit none

print *,recurse(64)
contains
recursive integer function recurse(n) result(v)
integer,intent(in)::n
if(n==0) then
v=0
else
v=1+recurse(n-1)
end if
end function
end program
