program kind_test
implicit none
integer :: undefined
print *, kind(selected_real_kind(undefined))
end program
