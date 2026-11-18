program p
implicit none
real(4)::aa(-1:1,2:4)
call random_number(aa)
print *,kind(aa),aa
end program p
