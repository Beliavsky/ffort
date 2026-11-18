program keyword_oracle
implicit none
integer :: aa(40000)
aa=1
call transform(second=aa+0,first=aa+0)
contains
subroutine transform(first,second)
integer,intent(in) :: first(:),second(:)
return
end subroutine transform

end program
