program section_oracle
implicit none
integer :: aa(4,4),ii,jj,kk
aa=0
do kk=1,4
aa(1:kk,kk)=kk
aa(kk,4:1:-1)=aa(kk,4:1:-1)+10
print *,aa(kk,:),size(aa(1:kk,kk))
end do
print *,aa
end program section_oracle
