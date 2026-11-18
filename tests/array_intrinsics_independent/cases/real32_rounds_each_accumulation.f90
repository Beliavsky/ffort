program array_intrinsic_oracle
implicit none
real :: aa(3),bb(3)
real(8) :: cc(3)
aa(1)=16777216.0
aa(2)=1.0
aa(3)=-16777216.0
bb=1.0
cc(1)=16777216.0d0
cc(2)=1.0d0
cc(3)=-16777216.0d0
print *,sum(aa),dot_product(aa,bb),sum(cc)
end program
