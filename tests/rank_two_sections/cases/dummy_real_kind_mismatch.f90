program section_oracle
implicit none
integer :: aa(3,3)
print *,999
call work(real(aa(:,:)))
contains
subroutine work(xx)
real(8),intent(in)::xx(:,:)
end subroutine
end program section_oracle
