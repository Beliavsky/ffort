program keyword_oracle
implicit none
integer :: aa,bb
call transform(second=bb,first=aa)
print *,aa,bb
contains
subroutine transform(first,second)
integer,intent(out) :: first,second
first=17
second=23
end subroutine transform

end program
