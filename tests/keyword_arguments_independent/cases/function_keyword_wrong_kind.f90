program keyword_oracle
implicit none

print *,777
print *,combine(value=3.0)
contains
real(8) function combine(value) result(result_value)
real(8),intent(in) :: value
result_value=value
end function combine

end program
