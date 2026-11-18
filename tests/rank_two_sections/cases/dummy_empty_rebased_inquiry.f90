program section_oracle
implicit none
integer :: aa(3,3)
call work(aa(2:1,:))
contains
subroutine work(xx)
integer,intent(in)::xx(-3:,7:)
print *,size(xx),lbound(xx,1),ubound(xx,1),lbound(xx,2),ubound(xx,2)
end subroutine
end program section_oracle
