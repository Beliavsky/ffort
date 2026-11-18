program p
implicit none
integer::aa
print *,kind(noisy(aa))
contains
impure elemental real(8) function noisy(xx) result(yy)
integer,intent(in)::xx
print *,991
yy=1.0d0
end function
end program p
