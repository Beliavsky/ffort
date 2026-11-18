program keyword_oracle
implicit none

print *,combine(2,3,third=4)
contains
integer function combine(first,second,third) result(result_value)
integer, intent(in) :: second,third,first
result_value=100*first+10*second+third
end function combine

end program
