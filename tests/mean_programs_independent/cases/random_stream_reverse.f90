program p
implicit none
real(8)::aa(6)
call random_number(aa(6:1:-1))
print *,aa
end program p
