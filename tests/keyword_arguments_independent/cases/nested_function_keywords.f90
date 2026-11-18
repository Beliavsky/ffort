program keyword_oracle
implicit none

print *,combine(second=combine(first=3,second=4),first=combine(second=2,first=1))
contains
integer function combine(first,second) result(result_value)
integer, intent(in) :: first,second
result_value=10*first+second
end function combine

end program
