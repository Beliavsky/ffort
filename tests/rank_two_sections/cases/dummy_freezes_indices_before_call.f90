program section_oracle
implicit none
integer :: aa(3,3),ii,jj
aa=1
ii=2
jj=3
call work(aa(ii,jj:1:-1),ii,jj)
print *,aa,ii,jj
contains
subroutine work(xx,ii,jj)
integer,intent(inout)::xx(:),ii,jj
ii=1
jj=1
xx=7
end subroutine
end program section_oracle
