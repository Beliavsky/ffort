program section_oracle
implicit none
integer :: aa(3,3),ii
aa=1
ii=4
print *,111
aa(:,1:ii)=3
end program section_oracle
