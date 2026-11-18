program array_intrinsic_oracle
implicit none
integer :: aa(-2:-2,4:5),bb(7:8,-1:1)
aa(-2,4)=-5
aa(-2,5)=-2
bb(7,-1)=-4
bb(8,-1)=4
bb(7,0)=1
bb(8,0)=-2
bb(7,1)=-1
bb(8,1)=-5
print *,matmul(aa,bb)
print *,matmul(aa(-2:-2:-1,5:4:-1),bb(8:7:-1,1:-1:-1))
print *,dot_product(aa(-2,:),bb(:,-1))

end program
