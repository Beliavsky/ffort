program p
implicit none
integer(8)::a(13)
a=[0_8,1_8,2_8,3_8,4_8,8_8,96_8,-1_8,-2_8,-3_8,-8_8,9223372036854775807_8,(-huge(0_8)-1_8)]
print *,trailz(a)
print *,kind(trailz(a)),kind(trailz(a(1)))
end program p
