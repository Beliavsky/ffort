program p
implicit none
real::aa(5)=-1.0
call random_number(aa(5:1:-2))
print *,aa
end program p
