program keyword_oracle
implicit none
real :: aa(4)
aa=3.5
print *,combine(value=int(aa))
contains
integer function combine(value) result(result_value)
integer,intent(in) :: value(:)
result_value=sum(array=value)
end function combine

end program
