program keyword_oracle
implicit none

print *,combine(factor=2.5d0,enabled=.true.,number=4)
contains
real(8) function combine(number,enabled,factor) result(result_value)
integer,intent(in) :: number
logical,intent(in) :: enabled
real(8),intent(in) :: factor
result_value=0.0d0
if (enabled) result_value=number+factor
end function combine

end program
