program array_intrinsic_oracle
implicit none
integer :: aa(3),zz
aa=1
zz=0
print *,maxval(aa/zz,.false.)
end program
