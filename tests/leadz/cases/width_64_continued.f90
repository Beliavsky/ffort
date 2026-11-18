program p
implicit none
integer(8)::a(14)
a=[0_8,1_8,2_8,3_8,7_8,127_8,128_8,4611686018427387903_8,4611686018427387904_8,9223372036854775807_8,(-1_8), &
& (-2_8),(-127_8),(-huge(0_8)-1_8)]
print *,leadz(a)
print *,kind(leadz(a)),kind(leadz(a(1)))
end program
