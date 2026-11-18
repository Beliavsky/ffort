program keyword_oracle
implicit none
integer :: aa,bb
print *,777
call transform(first=aa,bb)
contains
subroutine transform(first,second)
integer,intent(out) :: first,second
first=1
second=2
end subroutine transform

end program
