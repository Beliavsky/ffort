program kind_test
implicit none
integer :: p,r,base
integer(8) :: q
p=15
r=307
base=2
q=6_8
print *, selected_real_kind(p,r,base),selected_real_kind(p=q), &
kind(selected_real_kind(p)),selected_real_kind(r=37_8,p=6_8)
end program
