program keyword_oracle
implicit none
integer :: aa(2,2)
aa=3
print *,combine(value=real(aa))
contains
real function combine(value) result(result_value)
real,intent(in) :: value(:,:)
result_value=sum(array=value)
end function combine

end program
