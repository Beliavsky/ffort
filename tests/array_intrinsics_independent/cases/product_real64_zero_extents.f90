program array_intrinsic_oracle
implicit none
real(8) :: aa(0,3),bb(2,0),cc(0)
print *,product(aa),product(bb),product(cc),product(cc,1)
print *,product(aa,1),product(bb,2)
print *,size(product(aa,2)),size(product(bb,1))
end program
