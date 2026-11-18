program array_intrinsic_oracle
implicit none
real :: aa(0,3),bb(2,0),cc(0)
print *,minval(aa),minval(bb),minval(cc),minval(cc,1)
print *,minval(aa,1),minval(bb,2)
print *,size(minval(aa,2)),size(minval(bb,1))
end program
