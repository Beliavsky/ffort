program keyword_oracle
implicit none
integer :: aa
call transform(value=aa)
print *,aa
contains
subroutine transform(value)
integer,intent(inout) :: value
value=8
end subroutine transform

end program
