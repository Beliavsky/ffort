program array_intrinsic_oracle
implicit none
integer :: aa(-1:2),bb(4:7),cc(0)
aa(-1)=1
bb(4)=2
aa(0)=-2
bb(5)=3
aa(1)=3
bb(6)=-1
aa(2)=4
bb(7)=2
print *,dot_product(aa,bb),dot_product(aa(2:-1:-2),bb(4:7:2))
print *,dot_product(cc,cc)
end program
