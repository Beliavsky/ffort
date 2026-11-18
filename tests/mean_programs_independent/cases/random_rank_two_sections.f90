program p
implicit none
real(8)::aa(3,4)=-1d0
call random_number(aa(3:1:-2,4:1:-2))
print *,aa
end program p
