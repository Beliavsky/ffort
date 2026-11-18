program p
print *,f(1)
contains
recursive integer function f(n) result(v)
integer,intent(in)::n
if(n>0) then
v=19
v=f(n-1)
end if
end function
end program
