program p
implicit none
real(8)::aa(11)
call random_number(aa(1:11:2))
print *,aa(1:11:2)
end program p
