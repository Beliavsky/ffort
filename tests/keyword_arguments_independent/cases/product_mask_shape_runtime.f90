program keyword_oracle
implicit none
integer :: aa(2,2),nn,jj
logical :: mm(4,2)
aa=1
mm=.true.
nn=2
jj=1
print *,777
print *,product(array=aa,mask=mm(:nn,:jj))
end program
