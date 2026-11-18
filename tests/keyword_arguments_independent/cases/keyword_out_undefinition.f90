program keyword_oracle
implicit none
integer :: aa
aa=9
call transform(value=aa)
print *,aa
contains
subroutine transform(value)
integer,intent(out) :: value
return
end subroutine transform

end program
