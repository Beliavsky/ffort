program p
implicit none
real::aa(5)
aa(1)=8
aa(5)=9
call random_number(aa(2:4))
print *,aa
end program p
