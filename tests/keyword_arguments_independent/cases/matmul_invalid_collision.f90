program keyword_oracle
implicit none
integer :: aa(2,2),bb(2,2)
aa=1
bb=1
print *,777
print *,matmul(aa,matrix_a=aa)
end program
