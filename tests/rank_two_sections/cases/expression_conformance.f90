program section_oracle
implicit none
integer :: aa(3,3),nn
aa=1
nn=2
print *,111
print *,aa(1:nn,:)+aa(:,1:nn)
end program section_oracle
