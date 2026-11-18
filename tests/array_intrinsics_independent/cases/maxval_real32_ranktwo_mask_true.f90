program array_intrinsic_oracle
implicit none
real :: aa(-1:1,4:6)
logical :: mm(-1:1,4:6)
aa(-1,4)=-3.0
aa(0,4)=-2.0
aa(1,4)=-1.0
aa(-1,5)=-3.5
aa(0,5)=-2.5
aa(1,5)=-1.5
aa(-1,6)=-4.0
aa(0,6)=-3.0
aa(1,6)=-2.0
mm(-1,4)=.false.
mm(0,4)=.true.
mm(1,4)=.false.
mm(-1,5)=.true.
mm(0,5)=.false.
mm(1,5)=.true.
mm(-1,6)=.false.
mm(0,6)=.true.
mm(1,6)=.false.
print *,maxval(aa,.true.)
print *,maxval(aa,1,.true.)
print *,maxval(aa,2,.true.)

end program
