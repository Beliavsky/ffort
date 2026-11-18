program keyword_oracle
implicit none
integer :: aa(2)
aa=3
print *,combine(value=abs(-3))
contains
integer function combine(value) result(result_value)
integer,intent(in) :: value
result_value=value
end function combine

end program
