program keyword_oracle
implicit none

print *,777
print *,combine(first=2, &
 ! no positional restart
 3)
contains
integer function combine(first,second) result(result_value)
integer,intent(in) :: first,second
result_value=first+second
end function combine

end program
