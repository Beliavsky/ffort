program keyword_oracle
implicit none

print *,combine(result_value=2)
contains
integer function combine(first) result(result_value)
integer,intent(in) :: first
result_value=first
end function combine

end program
