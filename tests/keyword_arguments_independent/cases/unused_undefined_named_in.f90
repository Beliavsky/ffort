program keyword_oracle
implicit none
integer :: aa
call transform(unused=aa)
print *,7
contains
subroutine transform(unused)
integer,intent(in) :: unused
return
end subroutine transform

end program
