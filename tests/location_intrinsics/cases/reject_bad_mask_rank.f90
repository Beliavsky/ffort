program p
implicit none

print *,"NO OUTPUT"
print *,maxloc(reshape([1,2],[1,2]),mask=[.true.,.false.])
end program
