program p
implicit none
real::aa(0),bb(2,0)
call random_number(aa)
call random_number(bb)
print *,size(aa),size(bb)
end program p
