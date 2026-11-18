program array_intrinsic_oracle
implicit none
integer :: aa(-2:2,4:7)
logical :: mm(-2:2,4:7)
aa(-2,4)=-1
mm(-2,4)=.true.
aa(-1,4)=-2
mm(-1,4)=.true.
aa(0,4)=1
mm(0,4)=.true.
aa(1,4)=0
mm(1,4)=.false.
aa(2,4)=0
mm(2,4)=.false.
aa(-2,5)=-1
mm(-2,5)=.false.
aa(-1,5)=2
mm(-1,5)=.false.
aa(0,5)=2
mm(0,5)=.true.
aa(1,5)=0
mm(1,5)=.false.
aa(2,5)=1
mm(2,5)=.false.
aa(-2,6)=-2
mm(-2,6)=.true.
aa(-1,6)=0
mm(-1,6)=.false.
aa(0,6)=0
mm(0,6)=.false.
aa(1,6)=-1
mm(1,6)=.false.
aa(2,6)=2
mm(2,6)=.false.
aa(-2,7)=2
mm(-2,7)=.false.
aa(-1,7)=1
mm(-1,7)=.false.
aa(0,7)=-2
mm(0,7)=.true.
aa(1,7)=0
mm(1,7)=.false.
aa(2,7)=0
mm(2,7)=.false.
print *,sum(aa(1:1:1,4:7:1),mm(1:1:1,4:7:1))
print *,sum(aa(1:1:1,4:7:1),1,mm(1:1:1,4:7:1))
print *,sum(aa(1:1:1,4:7:1),2,mm(1:1:1,4:7:1))
print *,product(aa(1:1:1,4:7:1),mm(1:1:1,4:7:1))
print *,product(aa(1:1:1,4:7:1),1,mm(1:1:1,4:7:1))
print *,product(aa(1:1:1,4:7:1),2,mm(1:1:1,4:7:1))
print *,minval(aa(1:1:1,4:7:1),mm(1:1:1,4:7:1))
print *,minval(aa(1:1:1,4:7:1),1,mm(1:1:1,4:7:1))
print *,minval(aa(1:1:1,4:7:1),2,mm(1:1:1,4:7:1))
print *,maxval(aa(1:1:1,4:7:1),mm(1:1:1,4:7:1))
print *,maxval(aa(1:1:1,4:7:1),1,mm(1:1:1,4:7:1))
print *,maxval(aa(1:1:1,4:7:1),2,mm(1:1:1,4:7:1))

end program
