program array_intrinsic_oracle
implicit none
real :: aa(-1:2),bb(4:7),cc(0)
aa(-1)=0.5
bb(4)=1.0
aa(0)=-1.0
bb(5)=1.5
aa(1)=1.5
bb(6)=-0.5
aa(2)=2.0
bb(7)=1.0
print *,dot_product(aa,bb),dot_product(aa(2:-1:-2),bb(4:7:2))
print *,dot_product(cc,cc)
end program
