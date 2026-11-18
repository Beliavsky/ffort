program section_oracle
implicit none
integer :: aa(3,3)
aa=9
print *,111
call work(aa(:,1:3:2))
contains
subroutine work(xx)
integer,intent(out)::xx(:,:)
print *,xx(1,1)
end subroutine
end program section_oracle
