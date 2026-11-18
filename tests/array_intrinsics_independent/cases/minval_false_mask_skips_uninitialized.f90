program array_intrinsic_oracle
implicit none
integer :: aa(3)
print *,minval(aa,.false.)
end program
