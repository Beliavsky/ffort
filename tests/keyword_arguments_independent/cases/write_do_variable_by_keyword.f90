program keyword_oracle
implicit none
integer :: ii
do ii=1,2
call transform(first=ii)
end do
contains
subroutine transform(first)
integer,intent(out) :: first
first=2
end subroutine transform

end program
