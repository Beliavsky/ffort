program array_intrinsic_oracle
implicit none
integer :: aa(3),nn
nn=4
print *,111
print *,sum(aa(1:nn),.false.)
end program
