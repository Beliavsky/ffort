program p
implicit none
integer::aa(2),bb(3)
aa=[1,2]
bb=[noisy(aa),9]
print *,bb
contains
impure elemental integer function noisy(xx) result(yy)
integer,intent(in)::xx
print *,xx
yy=10*xx
end function
end program p
