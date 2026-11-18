program kind_test
implicit none
print *, selected_real_kind(10000),selected_real_kind(r=10000), &
selected_real_kind(10000,10000),selected_real_kind(radix=10)
end program
