program array_intrinsic_oracle
implicit none
integer :: aa(2,3),dd
aa(:,1)=1
aa(:,2)=2
aa(:,3)=3
do dd=1,2
print *,sum(aa,dd),size(sum(aa,dd))
end do
end program
