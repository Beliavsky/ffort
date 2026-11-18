program keyword_oracle
implicit none
real :: aa(-1:0,3:5)
logical :: mm(-1:0,3:5)
aa(-1,3)=2.5
mm(-1,3)=.true.
aa(0,3)=3.0
mm(0,3)=.false.
aa(-1,4)=3.5
mm(-1,4)=.false.
aa(0,4)=4.0
mm(0,4)=.true.
aa(-1,5)=4.5
mm(-1,5)=.true.
aa(0,5)=5.0
mm(0,5)=.false.
print *,maxval(dim=1,array=aa,mask=mm)
end program
