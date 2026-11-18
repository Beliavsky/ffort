program p
implicit none
integer(4)::a(-2:2)
a=[1_4,2_4,4_4,8_4,16_4]
print *,trailz(a(2:-2:-2))
print *,trailz((a))
end program p
