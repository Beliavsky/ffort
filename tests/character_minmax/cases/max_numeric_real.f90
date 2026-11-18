program p
implicit none

print *,max(-9.,0.,5.),max(-1d300,1d300),max(a2=7d0,a1=3d0),max([1.,2.,3.],2.)
end program
