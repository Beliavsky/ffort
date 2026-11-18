program kind_test
implicit none
real(selected_real_kind(15,307)) :: x
x=1.25
print *,kind(x),x
end program
