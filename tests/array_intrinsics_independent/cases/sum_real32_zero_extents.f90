program array_intrinsic_oracle
implicit none
real :: aa(0,3),bb(2,0),cc(0)
print *,sum(aa),sum(bb),sum(cc),sum(cc,1)
print *,sum(aa,1),sum(bb,2)
print *,size(sum(aa,2)),size(sum(bb,1))
end program
