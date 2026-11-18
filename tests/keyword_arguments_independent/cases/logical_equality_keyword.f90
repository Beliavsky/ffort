program keyword_oracle
implicit none
logical :: aa
aa=.true.
print *,combine(flag=aa.eqv..true.)
contains
logical function combine(flag) result(result_value)
logical,intent(in) :: flag
result_value=flag
end function combine

end program
