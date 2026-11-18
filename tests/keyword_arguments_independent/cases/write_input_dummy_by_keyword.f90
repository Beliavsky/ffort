program keyword_oracle
implicit none
integer :: aa
aa=1
call outer(value=aa)
contains
subroutine outer(value)
integer,intent(in) :: value
call transform(first=value)
end subroutine outer
subroutine transform(first)
integer,intent(out) :: first
first=2
end subroutine transform

end program
