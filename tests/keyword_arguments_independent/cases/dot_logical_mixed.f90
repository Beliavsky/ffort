program keyword_oracle
implicit none
logical :: aa(4),bb(-2:1)
aa=.true.
bb=.true.
print *,dot_product(aa,vector_b=bb)
end program
