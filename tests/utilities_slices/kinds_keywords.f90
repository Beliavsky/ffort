program kind_test
implicit none
print *, selected_real_kind(r=37),selected_real_kind(r=307,p=15),selected_real_kind(radix=2), &
selected_real_kind(p=6,radix=2),selected_real_kind(r=307,radix=2),selected_real_kind(), &
selected_real_kind(6,radix=2,r=37)
end program
