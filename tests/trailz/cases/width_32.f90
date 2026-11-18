program p
implicit none
integer(4)::a(13)
a=[0_4,1_4,2_4,3_4,4_4,8_4,96_4,-1_4,-2_4,-3_4,-8_4,2147483647_4,(-huge(0_4)-1_4)]
print *,trailz(a)
print *,kind(trailz(a)),kind(trailz(a(1)))
end program p
