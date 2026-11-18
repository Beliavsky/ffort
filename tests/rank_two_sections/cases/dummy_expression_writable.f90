program section_oracle
implicit none
integer :: aa(3,3)
print *,999
call work(aa(:,:)+1)
contains
subroutine work(xx)
integer,intent(inout)::xx(:,:)
xx=1
end subroutine
end program section_oracle
