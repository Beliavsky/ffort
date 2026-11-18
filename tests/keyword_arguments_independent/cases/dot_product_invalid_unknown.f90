program keyword_oracle
implicit none
integer :: aa(2),bb(2)
aa=1
bb=1
print *,777
print *,dot_product(vector_a=aa,no_such_keyword=bb)
end program
