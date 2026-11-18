program keyword_oracle
implicit none

print *,combine(first=500)
contains
integer function combine(first) result(result_value)
integer,intent(in) :: first
integer :: ii
result_value=0
do ii=1,first
result_value=result_value+ii
end do
end function combine

end program
