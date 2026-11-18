program keyword_oracle
implicit none

print *,combine(first=2)
contains
integer function combine(first,second) result(result_value)
integer,intent(in) :: first
integer,intent(in),optional :: second
result_value=first
end function combine

end program
