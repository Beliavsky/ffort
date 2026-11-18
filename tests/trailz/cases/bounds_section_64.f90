program p
implicit none
integer(8)::a(-2:2)
a=[1_8,2_8,4_8,8_8,16_8]
print *,trailz(a(2:-2:-2))
print *,trailz((a))
end program p
