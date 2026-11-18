program keyword_oracle
implicit none
logical :: aa(4),bb(-2:1)
aa=.true.
bb=.true.
print *,dot_product(VeCtOr_B=bb,VeCtOr_A=aa)
end program
