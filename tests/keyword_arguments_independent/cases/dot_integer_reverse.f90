program keyword_oracle
implicit none
integer :: aa(4),bb(-2:1)
aa=2
bb=3
print *,dot_product(vector_b=bb,vector_a=aa)
end program
