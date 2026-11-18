program array_intrinsic_oracle
implicit none
integer :: aa(2)
print *,111
aa=1
print *,sum(aa,axis=1)
end program
