program keyword_oracle
implicit none

print *,sum(right=2,left=8)
contains
integer function sum(left,right) result(result_value)
integer,intent(in) :: left,right
result_value=left-right
end function sum

end program
