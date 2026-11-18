program keyword_oracle
implicit none
integer :: aa(-2:2)
aa=3
print *,combine(scale=2,values=aa(2:-2:-2))
contains
integer function combine(values,scale) result(result_value)
integer,intent(in) :: values(0:),scale
result_value=scale*sum(array=values)+lbound(dim=1,array=values)
end function combine

end program
