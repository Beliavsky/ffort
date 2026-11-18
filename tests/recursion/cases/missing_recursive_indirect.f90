program p
implicit none

print *,even(3)
contains
recursive logical function even(n) result(v)
integer,intent(in)::n
if(n==0) then
v=.true.
else
v=odd(n-1)
end if
end function
logical function odd(n) result(v)
integer,intent(in)::n
if(n==0) then
v=.false.
else
v=even(n-1)
end if
end function
end program
