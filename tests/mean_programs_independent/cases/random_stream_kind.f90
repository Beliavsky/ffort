program p
implicit none
real(8)::aa(6)
integer::kk
kk=kind(draw(1))
call random_number(aa)
print *,aa
contains
impure elemental real(8) function draw(ii) result(xx)
integer,intent(in)::ii
call random_number(xx)
end function
end program p
