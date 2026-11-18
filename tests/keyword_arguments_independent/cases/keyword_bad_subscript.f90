program keyword_oracle
implicit none
integer :: aa(2),ii
ii=3
call transform(value=aa(ii))
contains
subroutine transform(value)
integer,intent(out) :: value
value=2
end subroutine transform

end program
