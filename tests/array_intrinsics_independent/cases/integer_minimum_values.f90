program array_intrinsic_oracle
implicit none
integer :: aa(2)
aa(1)=-2147483647-1
aa(2)=-2147483647-1
print *,minval(aa),maxval(aa),minval(aa(1:1)),maxval(aa(1:1))
end program
