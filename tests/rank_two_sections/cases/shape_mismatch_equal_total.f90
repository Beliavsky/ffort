program section_oracle
implicit none
integer :: aa(3,3),nn
aa=1
nn=2
print *,111
aa(1:nn,1:3)=aa(1:3,1:nn)
end program section_oracle
