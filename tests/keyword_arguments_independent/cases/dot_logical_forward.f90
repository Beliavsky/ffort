program keyword_oracle
implicit none
logical :: aa(4),bb(-2:1)
aa=.true.
bb=.true.
print *,dot_product(vector_a=aa,vector_b=bb)
end program
