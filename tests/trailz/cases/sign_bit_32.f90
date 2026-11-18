program p
implicit none
integer(4)::a
a=-huge(0_4)-1_4
print *,trailz(a),trailz(a+1_4),trailz(a+2_4)
end program p
