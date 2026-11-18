program p
implicit none
print *,trailz(ior(8,32)),trailz(iand(12,10)),leadz(trailz(0_8)),trailz(shiftr(-1_8,63))
end program p
