program keyword_oracle
implicit none
integer :: value
value=7
print *,combine(value=value)
contains
integer function combine(value) result(result_value)
integer,intent(in) :: value
result_value=value+1
end function combine

end program
