program array_intrinsic_oracle
implicit none
real(8) :: aa(0,3),bb(2,0),cc(0)
print *,maxval(aa),maxval(bb),maxval(cc),maxval(cc,1)
print *,maxval(aa,1),maxval(bb,2)
print *,size(maxval(aa,2)),size(maxval(bb,1))
end program
