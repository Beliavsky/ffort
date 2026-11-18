program section_oracle
implicit none
integer :: aa(3,3)
aa=9
call work(aa(2:1,:),aa(:,2:1))
print *,aa
contains
subroutine work(xx,yy)
integer,intent(inout)::xx(:,:),yy(:,:)
print *,size(xx),size(xx,1),size(xx,2),size(yy),size(yy,1),size(yy,2)
xx=1
yy=2
end subroutine
end program section_oracle
