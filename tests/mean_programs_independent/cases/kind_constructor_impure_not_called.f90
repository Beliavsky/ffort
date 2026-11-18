program p
implicit none

print *,kind([noisy(1),noisy(2)])
contains
impure elemental integer function noisy(xx) result(yy)
integer,intent(in)::xx
print *,xx
yy=10*xx
end function
end program p
