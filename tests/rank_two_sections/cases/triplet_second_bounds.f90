program section_oracle
implicit none
integer :: aa(3,3),ii
aa=1
ii=0
print *,111
print *,aa(:,3:ii:-1)
end program section_oracle
