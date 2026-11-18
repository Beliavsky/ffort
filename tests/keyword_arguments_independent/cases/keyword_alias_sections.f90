program keyword_oracle
implicit none
integer :: aa(5)
aa=1
call transform(second=aa(5:1:-2),first=aa(1:3))
contains
subroutine transform(first,second)
integer,intent(out) :: first(:),second(:)
return
end subroutine transform

end program
