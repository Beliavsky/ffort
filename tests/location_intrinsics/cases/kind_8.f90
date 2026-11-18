program p
implicit none

print *,minloc([3,1],kind=8),kind(minloc([3,1],kind=8)),maxloc([3,1],1,kind=8)
end program
