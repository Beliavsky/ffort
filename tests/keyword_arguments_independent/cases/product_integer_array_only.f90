program keyword_oracle
implicit none
integer :: aa(-1:0,3:5)
logical :: mm(-1:0,3:5)
aa(-1,3)=5
mm(-1,3)=.true.
aa(0,3)=6
mm(0,3)=.false.
aa(-1,4)=7
mm(-1,4)=.false.
aa(0,4)=8
mm(0,4)=.true.
aa(-1,5)=9
mm(-1,5)=.true.
aa(0,5)=10
mm(0,5)=.false.
print *,product(array=aa)
end program
