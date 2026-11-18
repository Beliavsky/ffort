program section_oracle
implicit none
integer :: aa(3,3)
aa=2
print *,111
call work(aa(1:3:2,1:3:2),aa(3,3))
contains
subroutine work(xx,yy)
integer,intent(inout)::xx(:,:)
integer,intent(in)::yy
print *,222
xx=yy
end subroutine
end program section_oracle
