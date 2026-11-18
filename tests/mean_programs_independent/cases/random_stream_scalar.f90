program p
implicit none
real(8)::aa
integer::ii
do ii=1,6
call random_number(aa)
print *,aa
end do
end program p
