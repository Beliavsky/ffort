program array_intrinsic_oracle
implicit none
integer :: aa(-2:-2,4:4),bb(7:7,-1:2)
aa(-2,4)=5
bb(7,-1)=-4
bb(7,0)=2
bb(7,1)=2
bb(7,2)=4
print *,matmul(aa,bb)
print *,matmul(aa(-2:-2:-1,4:4:-1),bb(7:7:-1,2:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
