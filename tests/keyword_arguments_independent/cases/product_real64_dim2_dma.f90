program keyword_oracle
implicit none
real(8) :: aa(-1:0,3:5)
logical :: mm(-1:0,3:5)
aa(-1,3)=2.5d0
mm(-1,3)=.true.
aa(0,3)=3.0d0
mm(0,3)=.false.
aa(-1,4)=3.5d0
mm(-1,4)=.false.
aa(0,4)=4.0d0
mm(0,4)=.true.
aa(-1,5)=4.5d0
mm(-1,5)=.true.
aa(0,5)=5.0d0
mm(0,5)=.false.
print *,product(dim=2,mask=mm,array=aa)
end program
