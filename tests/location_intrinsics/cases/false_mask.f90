program p
implicit none

print *,minloc([1,2],.false.),maxloc([1,2],1,mask=.false.),minloc(reshape([1,2,3,4],[2,2]),mask=.false.)
end program
