program section_oracle
implicit none
integer :: aa(3,3)
aa=9
call partial(aa(1:3:2,1:3:2))
print *,aa(2,2),aa(1,1)
print *,aa(3,3)
contains
subroutine partial(xx)
integer,intent(out)::xx(:,:)
xx(1,1)=7
end subroutine
end program section_oracle
