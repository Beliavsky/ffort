program keyword_oracle
implicit none
integer :: aa
aa=1
call transform(second=aa,first=aa)
contains
subroutine transform(first,second)
integer,intent(out) :: first,second
return
end subroutine transform

end program
