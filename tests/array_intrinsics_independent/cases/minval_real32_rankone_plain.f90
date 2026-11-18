program array_intrinsic_oracle
implicit none
real :: aa(-2:2)
aa(-2)=1.5
aa(-1)=-1.0
aa(0)=2.0
aa(1)=0.0
aa(2)=0.5
print *,minval(aa),minval(aa(2:-2:-2))
end program
