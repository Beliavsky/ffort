program p
implicit none

print *,minloc([5,2,2],1),maxloc([5,2,5],dim=1,back=.true.)
end program
