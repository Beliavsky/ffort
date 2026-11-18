program p
implicit none
integer::aa(3)
aa=[noisy(1),noisy(2),noisy(3)]
print *,aa
contains
impure elemental integer function noisy(xx) result(yy)
integer,intent(in)::xx
print *,xx
yy=10*xx
end function
end program p
