program array_intrinsic_oracle
implicit none
integer :: aa(-1:1,4:6)
logical :: mm(-1:1,4:6)
aa(-1,4)=-6
aa(0,4)=-4
aa(1,4)=-2
aa(-1,5)=-7
aa(0,5)=-5
aa(1,5)=-3
aa(-1,6)=-8
aa(0,6)=-6
aa(1,6)=-4
mm(-1,4)=.false.
mm(0,4)=.true.
mm(1,4)=.false.
mm(-1,5)=.true.
mm(0,5)=.false.
mm(1,5)=.true.
mm(-1,6)=.false.
mm(0,6)=.true.
mm(1,6)=.false.
print *,minval(aa,.true.)
print *,minval(aa,1,.true.)
print *,minval(aa,2,.true.)

end program
