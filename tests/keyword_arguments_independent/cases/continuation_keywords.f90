program keyword_oracle
implicit none

print *,combine( &
 ! complete-token continuation
 & second = 3, &
 & first = 2)
contains
integer function combine(first,second) result(result_value)
integer,intent(in) :: first,second
result_value=10*first+second
end function combine

end program
