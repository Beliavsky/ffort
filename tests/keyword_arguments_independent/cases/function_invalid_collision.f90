program keyword_oracle
implicit none
integer :: aa(2)
print *,777
print *,combine(1,first=2)
contains
integer function combine(first,second) result(result_value)
integer,intent(in) :: first,second
result_value=first-second
end function combine

end program
