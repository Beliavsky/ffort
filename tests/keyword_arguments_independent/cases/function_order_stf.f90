program keyword_oracle
implicit none

print *,combine(second=3,third=4,first=2)
contains
integer function combine(first,second,third) result(result_value)
integer, intent(in) :: third,first,second
result_value=100*first+10*second+third
end function combine

end program
