program p
implicit none

real(8)::s
s=nearest(0.0_8,1.0_8)
print *,nearest(1.0,s)>1.0,nearest(1.0,-s)<1.0
print *,kind(nearest(s=1.0,x=1d0)),kind(nearest(s=1d0,x=1.0))
end program
