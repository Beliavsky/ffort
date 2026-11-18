program p
implicit none
integer(8)::a(5)=[0_8,1_8,2_8,31_8,32_8]
print *,maskr(a,kind=4)
end program
