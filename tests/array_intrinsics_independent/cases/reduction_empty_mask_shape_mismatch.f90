program array_intrinsic_oracle
implicit none
integer :: aa(0,3),nn
logical :: mm(0,4)
nn=4
print *,111
print *,sum(aa,mm(:,1:nn))
end program
