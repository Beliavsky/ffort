program section_oracle
implicit none
integer :: aa(3,3)
aa=2
call work(aa(1:3:2,1:3:2),aa(1:3:2,1:3:2)+1)
print *,aa
contains
subroutine work(xx,yy)
integer,intent(inout)::xx(:,:)
integer,intent(in)::yy(:,:)
xx=xx+yy
end subroutine
end program section_oracle
