program keyword_oracle
implicit none
integer :: aa(2,3),bb(3,2)
aa(1,1)=3
aa(2,1)=4
aa(1,2)=5
aa(2,2)=6
aa(1,3)=7
aa(2,3)=8
bb(1,1)=0
bb(2,1)=1
bb(3,1)=2
bb(1,2)=-1
bb(2,2)=0
bb(3,2)=1
print *,matmul(matrix_b=bb,matrix_a=aa)
end program
