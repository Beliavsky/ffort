program section_oracle
implicit none
integer :: aa(3,3)
aa=2
call work(aa(1:3:2,:),aa(:,1:3:2))
contains
subroutine work(xx,yy)
integer,intent(in)::xx(:,:),yy(:,:)
print *,xx,yy
end subroutine
end program section_oracle
