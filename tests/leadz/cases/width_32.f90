program p
implicit none
integer(4)::a(14)
a=[0_4,1_4,2_4,3_4,7_4,127_4,128_4,1073741823_4,1073741824_4,2147483647_4,(-1_4),(-2_4),(-127_4),(-huge(0_4)-1_4)]
print *,leadz(a)
print *,kind(leadz(a)),kind(leadz(a(1)))
end program
