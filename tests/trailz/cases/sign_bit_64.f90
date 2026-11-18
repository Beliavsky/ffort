program p
implicit none
integer(8)::a
a=-huge(0_8)-1_8
print *,trailz(a),trailz(a+1_8),trailz(a+2_8)
end program p
