program keyword_oracle
implicit none
integer :: aa(2)
aa=3
print *,combine(value=sqrt(4.0))
contains
real function combine(value) result(result_value)
real,intent(in) :: value
result_value=value
end function combine

end program
