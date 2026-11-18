program section_oracle
implicit none
integer :: aa(3,3)
aa=9
call fill(aa(1:3:2,3:1:-2))
print *,aa
contains
subroutine fill(xx)
integer,intent(out)::xx(:,:)
xx=7
end subroutine
end program section_oracle
