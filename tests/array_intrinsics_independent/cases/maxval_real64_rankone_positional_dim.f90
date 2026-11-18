program array_intrinsic_oracle
implicit none
real(8) :: aa(-2:2)
aa(-2)=1.5d0
aa(-1)=-1.0d0
aa(0)=2.0d0
aa(1)=0.0d0
aa(2)=0.5d0
print *,maxval(aa,1),maxval(aa(2:-2:-2),1)
end program
