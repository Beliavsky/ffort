program p
implicit none
real::aa(3,3)=-1.0
call random_number(aa(2,3:1:-1))
print *,aa
end program p
