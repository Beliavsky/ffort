program keyword_oracle
implicit none
integer :: aa
aa=4
call transform(value=aa,old_value=aa+3)
print *,aa
contains
subroutine transform(old_value,value)
integer,intent(in) :: old_value
integer,intent(out) :: value
value=old_value*2
end subroutine transform

end program
