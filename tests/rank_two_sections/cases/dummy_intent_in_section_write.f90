program section_oracle
implicit none
integer :: aa(3,3)
print *,999
call outer(aa)
contains
subroutine outer(xx)
integer,intent(in)::xx(:,:)
xx(:,1)=2
end subroutine
end program section_oracle
