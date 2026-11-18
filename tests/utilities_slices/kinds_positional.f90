program kind_test
implicit none
integer,parameter :: sp=selected_real_kind(6,37),dp=selected_real_kind(15,307)
real(dp) :: x
x=1.0_dp
print *, sp,dp,selected_real_kind(6),kind(x),kind(selected_real_kind(6))
end program
