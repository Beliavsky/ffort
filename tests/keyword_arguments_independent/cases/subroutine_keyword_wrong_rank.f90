program keyword_oracle
implicit none
integer :: aa
print *,777
call transform(value=aa)
contains
subroutine transform(value)
integer,intent(out) :: value(:)
value=3
end subroutine transform

end program
