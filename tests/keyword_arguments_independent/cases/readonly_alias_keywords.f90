program keyword_oracle
implicit none
integer :: aa(3)
aa=2
print *,combine(right=aa,left=aa)
contains
integer function combine(left,right) result(result_value)
integer,intent(in) :: left(:),right(:)
result_value=sum(array=left)+sum(array=right)
end function combine

end program
