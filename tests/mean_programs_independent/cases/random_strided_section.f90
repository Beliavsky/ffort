program p
implicit none
real(8)::aa(-2:3)=-1d0
call random_number(aa(-2:3:2))
print *,aa
end program p
