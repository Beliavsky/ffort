program keyword_oracle
implicit none

print *,combine(first=2,second=3,third=4)
contains
integer function combine(first,second,third) result(result_value)
integer, intent(in) :: third,first,second
result_value=100*first+10*second+third
end function combine

end program
