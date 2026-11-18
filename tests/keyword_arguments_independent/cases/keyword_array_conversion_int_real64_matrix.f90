program keyword_oracle
implicit none
real(8) :: aa(2,2)
aa=3.5d0
print *,combine(value=int(aa))
contains
integer function combine(value) result(result_value)
integer,intent(in) :: value(:,:)
result_value=sum(array=value)
end function combine

end program
