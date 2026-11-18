program section_oracle
implicit none
integer :: aa(3,3)
aa=3
aa(1,1)=2
aa(2,1)=1
aa(aa(2,1):aa(1,1),aa(2,1):aa(1,1))=9
print *,aa
end program section_oracle
