program p
implicit none
integer(8)::a(5)=[0_8,1_8,2_8,63_8,64_8]
print *,maskl(a,kind=8)
end program
