program array_intrinsic_oracle
implicit none
integer :: aa(2)
print *,111
aa=1
print *,sum(aa,1,dim=1)
end program
