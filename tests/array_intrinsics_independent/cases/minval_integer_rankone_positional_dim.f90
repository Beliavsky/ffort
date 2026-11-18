program array_intrinsic_oracle
implicit none
integer :: aa(-2:2)
aa(-2)=3
aa(-1)=-2
aa(0)=4
aa(1)=0
aa(2)=1
print *,minval(aa,1),minval(aa(2:-2:-2),1)
end program
