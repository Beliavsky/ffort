program array_intrinsic_oracle
implicit none
integer :: aa(2,3),nn
logical :: mm(2,3)
print *,111
aa=1
mm=.true.
nn=2
print *,sum(aa,mm(:,1:nn))
end program
