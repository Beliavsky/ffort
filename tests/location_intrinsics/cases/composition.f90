program p
implicit none

print *,sum(minloc(reshape([4,1,2,3],[2,2]),1)),pack(maxloc(reshape([4,1,2,3],[2,2]),2),[.true.,.false.])
end program
