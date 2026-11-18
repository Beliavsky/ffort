program array_intrinsic_oracle
implicit none
integer :: aa(-2:-1,4:4),bb(7:7,-1:1)
aa(-2,4)=3
aa(-1,4)=5
bb(7,-1)=0
bb(7,0)=5
bb(7,1)=3
print *,matmul(aa,bb)
print *,matmul(aa(-1:-2:-1,4:4:-1),bb(7:7:-1,1:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
