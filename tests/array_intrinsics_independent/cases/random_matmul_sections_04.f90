program array_intrinsic_oracle
implicit none
integer :: aa(-2:-1,4:5),bb(7:8,-1:2)
aa(-2,4)=-3
aa(-1,4)=5
aa(-2,5)=0
aa(-1,5)=5
bb(7,-1)=-5
bb(8,-1)=-3
bb(7,0)=-3
bb(8,0)=-4
bb(7,1)=1
bb(8,1)=3
bb(7,2)=-2
bb(8,2)=-4
print *,matmul(aa,bb)
print *,matmul(aa(-1:-2:-1,5:4:-1),bb(8:7:-1,2:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
