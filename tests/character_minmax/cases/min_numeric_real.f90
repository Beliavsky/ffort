program p
implicit none

print *,min(-9.,0.,5.),min(-1d300,1d300),min(a2=7d0,a1=3d0),min([1.,2.,3.],2.)
end program
