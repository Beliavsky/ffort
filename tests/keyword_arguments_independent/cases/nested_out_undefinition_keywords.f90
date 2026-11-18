program keyword_oracle
implicit none
integer :: aa
call transform(value=aa)
print *,aa
contains
subroutine transform(value)
integer,intent(out) :: value
value=3
call clear_value(target=value)
end subroutine transform
subroutine clear_value(target)
integer,intent(out) :: target
return
end subroutine clear_value

end program
