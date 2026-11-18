program p
implicit none
real(8)::aa(6),bb(0),cc(2,0)
call random_number(bb)
call random_number(cc)
call random_number(aa(3:1))
call random_number(aa)
print *,aa
end program p
