program keyword_oracle
implicit none
integer :: aa,bb
aa=2
bb=3
call transform(second=bb,first=aa)
print *,aa,bb
contains
subroutine transform(first,second)
integer,intent(inout) :: first,second
first=first*10
second=second+7
end subroutine transform

end program
