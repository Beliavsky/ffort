program keyword_oracle
implicit none
integer :: aa(2,3),bb(3,2)
aa=2
bb=3
print *,sum(dim=1,array=matmul(matrix_b=bb,matrix_a=aa))
print *,dot_product(vector_b=sum(dim=2,array=aa),vector_a=sum(dim=1,array=bb))
end program
