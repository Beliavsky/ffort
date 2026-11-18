program p
implicit none
real(8)::aa(2,2)
call random_number(aa(1:bound(2),1:bound(2)))
print *,aa
contains
impure elemental integer function bound(nn) result(rr)
integer,intent(in)::nn
real(8)::dd
call random_number(dd)
print *,dd
rr=nn
end function
end program p
