program keyword_oracle
implicit none
integer :: aa(6)
aa=1
call transform(second=aa(6:2:-2),first=aa(1:5:2))
print *,aa
contains
subroutine transform(first,second)
integer,intent(out) :: first(:),second(:)
first=3
second=7
end subroutine transform

end program
