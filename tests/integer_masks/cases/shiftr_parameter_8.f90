program p
implicit none
integer(8),parameter::a=shiftr(-1_8,64_8)
print *,a,kind(a)
end program
