program keyword_oracle
implicit none
real(8) :: aa(4),bb(-2:1)
aa=0.5d0
bb=0.25d0
print *,dot_product(aa,vector_b=bb)
end program
