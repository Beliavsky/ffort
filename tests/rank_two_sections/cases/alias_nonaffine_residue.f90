program section_oracle
implicit none
integer :: aa(3,3)
aa=2
print *,111
call work(aa(1,2),aa(1:3:2,1:2))
contains
subroutine work(xx,yy)
integer,intent(inout)::xx
integer,intent(in)::yy(:,:)
print *,222
xx=1
end subroutine
end program section_oracle
